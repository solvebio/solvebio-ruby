# -*- coding: utf-8 -*-
module SolveBio
    class Query
        # A Query API request wrapper that generates a request from Filter
        # objects, and can iterate through streaming result sets.
        include Enumerable

        # 2**62 - 1 fits Rubywise into a 64-bit Fixnum
        INT_MAX ||= 4_611_686_018_427_387_903

        # The maximum number of results fetched in one go. Note however
        # that iterating over a query can cause more fetches.
        DEFAULT_PAGE_SIZE ||= 100

        attr_reader   :dataset_id
        attr_accessor :filters
        attr_accessor :limit
        attr_accessor :page_size
        attr_accessor :range
        attr_reader   :response
        attr_reader   :page_offset

        # Creates a new Query object.
        #
        # Parameters:
        #   - `dataset_id`: Unique ID of dataset to query.
        #   - `genome_build`: The genome build to use for the query.
        #   - `fields` (optional): List of specific fields to retrieve.
        #   - `filters` (optional): List of filter objects.
        #   - `limit` (optional): Maximum number of query results to return.
        #   - `page_size` (optional): Max number of results to fetch per query page.
        def initialize(dataset_id, params={})
            unless dataset_id.is_a?(Fixnum) or dataset_id.respond_to?(:to_str)
                raise TypeError, "'dataset_id' parameter must an Integer or String"
            end

            @dataset_id   = dataset_id
            @data_url     = params[:data_url] || "/v1/datasets/#{dataset_id}/data"
            @genome_build = params[:genome_build]
            @fields       = params[:fields]
            @filters      = params[:filters].kind_of?(SolveBio::Filter) ? params[:filters].filters : (params[:filters] || [])

            @response     = nil
            # Limit defines the total number of results that will be returned
            # from a query involving 1 or more pagination requests.
            @limit        = params[:limit] || INT_MAX
            # Page limit and page offset are the low level API limit and offset params.
            # page_offset may be changed periodically during sequential pagination requests.
            @page_size   = params[:page_size] || DEFAULT_PAGE_SIZE
            # Page offset can only be set by execute()
            # It always contains the current absolute offset contained in the buffer.
            @page_offset  = nil
            # @range is set to tell the Query object that is being sliced and "def each" should not
            # reset the page_offset to 0 before iterating.
            @range        = nil

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
            q = Query.new(@dataset_id, {
                :data_url => @data_url,
                :genome_build => @genome_build,
                :fields => @fields,
                :limit => @limit,
                :page_size => @page_size
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
            return clone([GenomicFilter.new(chromosome, start, stop, exact)])
        end

        # Shortcut to do a single position filter on genomic datasets.
        def position(chromosome, position, exact=false)
            return clone([GenomicFilter.new(chromosome, position, position, exact)])
        end

        # Returns the total number of results in the result-set.
        # The count is dependent on the filters, but independent of any limit.
        # It is like SQL:
        # SELECT COUNT(*) FROM <depository> [WHERE condition].
        # See also size() a function that is dependent on limit.
        # Requires at least one request.
        def count 
            execute unless @response
            @response[:total]
        end
        alias_method(:total, :count)

        # Returns the total number of results that will be retrieved
        # given @limit set by the user.
        # Requires at least one API request to retrieve the total count.
        #
        # In SQL it is like:
        # SELECT COUNT(*) FROM (
        #     SELECT * FROM <table> [WHERE condition] [LIMIT number]
        # )
        def size
            [@limit, count].min
        end
        alias_method(:length, :size)

        def empty?
            return size == 0
        end

        # Convert SolveBio::QueryPaging object to a String type
        def to_s
            if @limit == 0 || count == 0
                return 'Query returned 0 results'
            end

            result = Tabulate.tabulate(buffer[0], ['Fields', 'Data'], ['right', 'left'], true)
            return "\n#{result}\n\n... #{(count - 1).pretty_int} more results."
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
                start = (key.begin < 0) ? (count + key.begin) : key.begin
                stop = (key.end < 0) ? (count + key.end) : key.end

                # Does the current buffer contain the desired range?
                if buffer && start >= @page_offset && stop < (@page_offset + buffer.length)
                    # Cursor's buffer has the items already
                    # Avoid a query and just return the buffered items.
                    # Calculate the offsets relative to the buffer.
                    start = start - @page_offset
                    stop = stop - @page_offset - 1
                    return buffer[start..stop]
                end

                # We need to make a few requests to get the data between start and stop.
                # We should respect the user's @limit (used by each()) if it is smaller than the given Range.
                # To prevent the state of page_size and page_offset from being stored, we'll clone this object first.
                q = clone()
                q.limit = [stop-start, @limit].min
                # Setting range will signal to "each" which page_offset to start at.
                q.range = Range.new(start, stop)
                
                results = []
                q.each do |r|
                    results << r
                end
                return results
            end

            # If the value at key is already in the buffer, return it.
            if buffer && key >= @page_offset && key < (@page_offset + buffer.length)
                return buffer[key - @page_offset]
            end

            if key < 0
                raise IndexError, 'Negative indexing is not supported'
            end
            
            # Otherwise, use key as the new page_offset and fetch a new page of results
            q = clone()
            q.limit = [1, @limit].min
            q.execute(key)
            return q.buffer[0]
        end
        
        def each(*args)
            return self unless block_given?

            # When calling each, we always reset the offset and buffer, unless called from
            # the slice function (def []).
            if @range
                execute(@range.begin)
            else
                execute(0)
            end

            # Keep track when iterating through the buffer
            buffer_idx = 0
            # This will yield a max of @limit or count() results, whichever comes first.
            0.upto(size - 1).each do |i|
                # i is the current index within the result-set.
                # @page_offset + i is the current absolute index within the result-set.

                if buffer_idx == buffer.length
                    # No more buffer! Get more results
                    execute(@page_offset + buffer_idx)
                    # Reset the buffer index.
                    buffer_idx = 0
                end

                yield buffer[buffer_idx]
                buffer_idx += 1
            end
        end

        def to_range(range_or_idx)
            return range_or_idx.kind_of?(Range) ? range_or_idx :
                (range_or_idx..range_or_idx + 1)
        end

        def buffer
            return nil unless @response
            @response[:results]
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

        def execute(offset=0)
            # Executes the current query.
            params = build_query()

            # Always set the page offset before querying.
            @page_offset = offset

            params.merge!(
                :offset => @page_offset,
                # The user's limit trumps the page limit if it's smaller
                :limit => [@page_size, @limit].min
            )

            SolveBio::logger.debug("Executing query with offset: #{params[:offset]} limit: #{params[:limit]}")
            @response = Client.post(@data_url, params)
            SolveBio::logger.debug("Query response took #{@response[:took]}ms, buffer size: #{buffer.length}, total: #{@response[:total]}")
            return params, @response
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
                q.merge!(
                    :dataset => i.dataset_id,
                    :limit => [i.page_size, i.limit].min
                )
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
