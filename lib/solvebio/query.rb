# -*- coding: utf-8 -*-
module SolveBio
    class Query
        # A Query API request wrapper that generates a request from Filter
        # objects, and can iterate through streaming result sets.
        include Enumerable

        # 2**62 - 1 fits Rubywise into a 64-bit Fixnum
        INT_MAX ||= 4_611_686_018_427_387_903
        DEFAULT_LIMIT ||= INT_MAX

        # The maximum number of results fetched in one go. Note however
        # that iterating over a query can cause more fetches.
        DEFAULT_PAGE_SIZE ||= 100

        attr_reader   :dataset_id
        attr_accessor :filters
        attr_accessor :limit
        attr_accessor :page_size
        attr_reader   :response

        # Creates a new Query object.
        #
        # Parameters:
        #   - `dataset_id`: Unique ID of dataset to query.
        #   - `genome_build`: The genome build to use for the query.
        #   - `fields` (optional): List of specific fields to retrieve.
        #   - `filters` (optional): List of filter objects.
        #   - `limit` (optional): Maximum number of query results to return.
        #   - `page_size` (optional): Number of results to fetch per query page.
        def initialize(dataset_id, params={})
            unless dataset_id.is_a?(Fixnum) or dataset_id.respond_to?(:to_str)
                raise TypeError, "'dataset_id' parameter must an Integer or String"
            end

            @dataset_id   = dataset_id
            @data_url     = params[:data_url] || "/v1/datasets/#{dataset_id}/data"
            @filters      = params[:filters] || []
            @genome_build = params[:genome_build]

            @response     = nil
            @count        = nil
            @page_size    = params[:page_size] || DEFAULT_PAGE_SIZE
            @limit        = params[:limit] || DEFAULT_LIMIT
            @fields       = params[:fields]

            @cursor       = Cursor.new()

            begin
                @limit = Integer(@limit)
                raise RangeError if @limit < 0
            rescue
                raise TypeError, "'limit' parameter must an Integer >= 0"
            end

            begin
                @page_size = Integer(@page_size)
                raise RangeError if @page_size <= 0
            rescue
                raise TypeError, "'page_size' parameter must an Integer > 0"
            end

            self
        end

        def clone(filters=[])
            q = initialize(@dataset_id, {
                :data_url => @data_url,
                :genome_build => @genome_build,
                :limit => @limit,
                :page_size => @page_size,
                :fields => @fields
            })

            q.filters += @filters unless @filters.empty?
            q.filters += filters unless filters.empty?
            q
        end

        # Returns this Query instance with the query args combined with
        # existing set with AND.
        #
        # kwargs are simply passed to a new SolveBio::Filter object and
        # combined to any other filters with AND.
        #
        # By default, everything is combined using AND. If you provide
        # multiple filters in a single filter call, those are ANDed
        # together. If you provide multiple filters in multiple filter
        # calls, those are ANDed together.
        #
        # If you want something different, use the F class which supports
        # ``&`` (and), ``|`` (or) and ``~`` (not) operators. Then call
        # filter once with the resulting Filter instance.
        def filter(params={}, conn=:and)
            return clone(Filter.new(params, conn).filters)
        end

        # Shortcut to do range queries on supported datasets.
        def range(chromosome, start, stop, exact=false)
            return self.clone([GenomicFilter.new(chromosome, start, stop, exact)])
        end

        # Shortcut to do a single position filter on genomic datasets.
        def position(chromosome, position, exact=false)
            return self.clone([GenomicFilter.new(chromosome, position, position, exact)])
        end

        # Returns the total number of results of the Query.
        # The count is dependent on the filters, but independent of any limit.
        # It is like SQL:
        # SELECT COUNT(*) FROM <depository> [WHERE condition].
        # See also size() a function that is dependent on limit.
        def count
            if @count.nil?
                q = clone
                q.limit = 0
                @count = q.total
            end
            @count
        end
        
        # Returns the total number of results in the result-set.
        # Requires at least one request.
        def total
            warmup
            @response[:total]
        end

        # Returns the total number of results that will be retrieved
        # given @limit set by the user.
        # Requires at least one API request to retrieve the total count.
        #
        # In SQL it is like:
        # SELECT COUNT(*) FROM (
        #     SELECT * FROM <table> [WHERE condition] [LIMIT number]
        # )
        def size
            warmup
            [@limit, total].min
        end
        alias_method :length, :size

        def offset
            @cursor.query_offset
        end

        def empty?
            return size == 0
        end

        # Convert SolveBio::QueryPaging object to a String type
        def to_s
            if total == 0 or @limit == 0
                return 'Query returned 0 results'
            end

            # By now there should be data in the cursor buffer
            result = Tabulate.tabulate(@cursor.first, ['Fields', 'Data'], ['right', 'left'], true)
            return "\n#{result}\n\n... #{(total - 1).pretty_int} more results."
        end

        # Convert SolveBio::QueryPaging object to a Hash type
        def to_h
            self[0]
        end

        # Retrieve an item or range from the set of results
        def [](key)
            unless [Range, Fixnum].member?(key.class)
                raise TypeError, "Expecting index value to be a Range or Fixnum; is #{key.class}"
            end

            if key.kind_of?(Range)
                # Reverse ranges aren't supported
                return [] if (key.begin > key.end)

                # Handle negative values for begin and end.
                # Negative values are relative to the length (see size) of the result-set.
                start = (key.begin < 0) ? (size + key.begin) : key.begin
                stop = (key.end < 0) ? (size + key.end) : key.end

                if @cursor.has_range?(start, stop)
                    # Cursor's buffer has the items already
                    # Avoid a query and just return the buffered items.
                    # Calculate the offsets relative to the cursor buffer.
                    start = start - @cursor.query_offset
                    stop = stop - @cursor.query_offset - 1
                    return @cursor.buffer[start..stop]
                end

                # Reset the Cursor's offset so that it is internally referencing
                # the start of the requested key. If the offset is out of bounds
                # (i.e. less than 0 or greater than cursor stop) the query will
                # request a new result page in each().
                # @cursor.reset_absolute(first)
                
                # Reset the cursor completely and set the desired offset
                @cursor.reset(start)
                @limit = stop - start

                results = []
                self.each do |r|
                    results << r
                end
                return results
            end

            if key < 0
                raise IndexError, 'Negative indexing is not supported'
            end

            if @cursor.has_key?(key)
                return @cursor.buffer[key - @cursor.query_offset]
            end

            # if key >= size
            #     raise IndexError, 'Index beyond end of results'
            # end

            # Otherwise, use key as the new query_offset and fetch a new page of results
            @cursor.reset(key)
            execute
            return @cursor.buffer[0]
        end

        # range operations
        def to_range(range_or_idx)
            return range_or_idx.kind_of?(Range) ? range_or_idx :
                (range_or_idx..range_or_idx + 1)
        end

        def build_query
            q = {}

            if @filters
                filters = Filter.process_filters(@filters)
                if filters.size > 1
                    q[:filters] = [{:and => filters}]
                else
                    q[:filters] = filters
                end
            end

            q[:fields] = @fields if @fields
            q[:genome_build] = @genome_build if @genome_build

            return q
        end

        def warmup
            execute unless @response
        end

        def execute
            _params = build_query()

            # The API limit param is really the page size
            _params.merge!(
                :offset => @cursor.query_offset,
                :limit => [@page_size, @limit].min
            )

            SolveBio::logger.debug("Executing query with offset: #{_params[:offset]} limit: #{_params[:limit]}")
            @response = Client.post(@data_url, _params)
            SolveBio::logger.debug("Query response took: #{@response[:took]}ms total: #{@response[:total]}")
            @cursor.set_buffer(@response[:results])
            return _params, @response
        end

        def each(*pass)
            # "each" must be defined in an Enumerator. Allows the Query object
            # to be an iterable.
            # Returns a maximum of @limit results, using @cursor to track
            # the iteration.
            return self unless block_given?

            # From 0 to the minimum of @limit or @count)
            # If the buffer has next, return next
            # Otherwise execute.
            0.upto(size - 1).each do |i|
                if not @cursor.has_next?
                    # Set the next query offset
                    @cursor.query_offset += @cursor.buffer_offset || 0
                    execute
                end
                yield @cursor.next
            end
        end
    end

    # BatchQuery accepts a list of Query objects and executes them
    # in a single request to /v1/batch_query.
    class BatchQuery
        # Expects a list of Query objects.
        def initialize(queries)
            unless queries.kind_of?(Array)
                queries = [queries]
            end

            @queries = queries
        end

        def build_query
            query = {:queries => []}

            @queries.each do |i|
                q = i.build_query
                limit =
                    if i.limit == Query::INT_MAX
                        i.page_size
                    else
                        [i.page_size, i.limit - i.offset].min
                    end
                q.merge!(:dataset => i.dataset_id, :limit => limit,
                         :offset => i.offset)
                query[:queries] << q
            end

            return query
        end

        def execute(params={})
            _params = build_query()
            _params.merge!(params)
            response = Client.post('/v1/batch_query', _params)
            return response
        end
    end
end
