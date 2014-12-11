# -*- coding: utf-8 -*-
# require 'pp'
# require_relative 'client'
# require_relative 'cursor'
# require_relative 'filter'
# require_relative 'locale'
# require_relative 'tabulate'

# A Query API request wrapper that generates a request from Filter
# objects, and can iterate through streaming result sets.
module SolveBio
    class Query
        include Enumerable

        # 2**62 - 1 fits Rubywise into a 64-bit Fixnum
        INT_MAX ||= 4_611_686_018_427_387_903

        # The maximum number of results fetched in one go. Note however
        # that iterating over a query can cause more fetches.
        DEFAULT_PAGE_SIZE ||= 1000

        attr_reader   :dataset_id
        attr_accessor :filters
        attr_accessor :limit
        attr_reader   :page_size
        attr_reader   :response

        # Creates a new Query object.
        #
        # Parameters:
        #   - `dataset_id`: Unique ID of dataset to query.
        #   - `genome_build`: The genome build to use for the query.
        #   - `result_class` (optional): Class of object returned by query.
        #   - `fields` (optional): List of specific fields to retrieve.
        #   - `filters` (optional): List of filter objects.
        #   - `limit` (optional): Maximum number of query results to return.
        #   - `page_size` (optional): Number of results to fetch per query page.
        def initialize(dataset_id, params={})
            @data_url     = "/v1/datasets/#{dataset_id}/data"
            @limit        = INT_MAX
            @result_class = params[:result_class]
            @filters      = params[:filters] || []
            @genome_build = params[:genome_build]
            @total        = nil
            @response     = nil
            @count        = nil
            @cursor       = Cursor.new(0 , -1, 0)
            @page_size    = params[:page_size] || DEFAULT_PAGE_SIZE

            begin
                @limit = Integer(params[:limit])
            rescue
                raise TypeError, "'limit' parameter must an Integer >= 0"
            end if params.member?(:limit)

            @result_class = params[:result_class] || Hash
            @fields = params[:fields]

            # parameter error checking
            if @limit < 0
                raise RangeError, "'limit' parameter must be >= 0"
            end

            self
        end

        def total
            warmup('Query total') unless @total
            @total
        end

        def clone(filters=[])
            result =
                initialize(@dataset_id,
                           {
                               :genome_build => @genome_build,
                               :limit => @limit,
                               :total => total,  # This causes an HTTP request
                               :result_class => @result_class,
                               :fields => @fields
                           })

            result.filters += @filters unless @filters.empty?
            result.filters += filters unless filters.empty?

            return result
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
            # TODO: ensure dataset supports range queries?
            return self.clone(GenomicFilter
                                 .new(chromosome, start, stop, exact))
        end

        # Shortcut to do a single position filter on genomic datasets.
        def position(chromosome, position, exact=false)
            return self.clone(GenomicFilter
                                 .new(:filters =>
                                      [GenomicFilter
                                          .new(chromosome, position, position,
                                               exact)]))
        end

        #
        # Returns the total number of results returned by a query.
        # The count is dependent on the filters, but independent of any limit.
        # It is like SQL:
        # SELECT COUNT(*) FROM <depository> [WHERE condition].
        # See also size() a function that is dependent on limit.
        def count
            unless @count
                limit_save = @limit
                response_save = @response
                @limit = INT_MAX
                @response = nil
                warmup('Query count')
                @count = @response['total']
                @limit = limit_save
                @response = response_save
            end
            @count
        end

        # Returns the total number of results returned in a query. It is the
        # number of items you can iterate over.
        #
        # In contrast to count(), the result does take into account any limit
        # given. In SQL it is like:
        #
        # SELECT COUNT(*) FROM (
        #     SELECT * FROM <table> [WHERE condition] [LIMIT number]
        # )
        def size
            [@limit, count].min
        end
        alias_method :length, :size

        def empty?
            return size == 0
        end

        # Convert SolveBio::QueryPaging object to a String type
        def to_s
            if total == 0 or @limit == 0
                return 'query returned 0 results'
            end

            sorted_items = Tabulate.
                tabulate(self[0], ['Fields', 'Data'], ['right', 'left'], true)
            msg =
                "\n%s\n\n... %s more results." %
                [sorted_items,
                 (@total - 1).pretty_int]
            return msg
        end

        def to_pp
            if total == 0 or @limit == 0
                return 'query returned 0 results'
            end
            msg = "\n#{self[0].pretty_inspect}\n" +
                "\n... #{(@total-1).pretty_int} more results."
            return msg
        end

        # Convert SolveBio::QueryPaging object to a Hash type
        def to_h
            self[0]
        end

        def inspect
            return '<%s: @dataset_id=%s, @total=%s, @limit=%s>' %
                [self.class, @dataset_id, @total ? @total : '?', @limit]
        end

        # warmup result set...
        def warmup(what)
            unless @response
                SolveBio::logger.debug("warmup #{what}")
                execute
            end
        end


        # FIXME: consider creating instance variables from
        # a response object and then using attr_reader to make that
        # visible. This is instead of:
        # # One hacky way to define attributes (methods) on an object.
        # # Replaces Python's __getattr__
        # def method_missing(meth, *args, &block)
        #     if @response.nil?
        #         logger.debug('warmup ([]): %s' % key)
        #         execute
        #     end

        #     if @response.member?(meth)
        #         return @response[meth]
        #     end

        #     msg = "'%s' object has no attribute '%s'" % [self.class, meth]
        #     raise NoMethodError, msg
        # end

        # Retrieve an item or range from the set of results
        def [](key)
            # warmup result set...
            warmup("[#{key}]")

            unless [Range, Fixnum].member?(key.class)
                raise TypeError, "Expecting index value to be a Range or Fixnum; is #{key.class}"
            end
            if @limit < 0
                raise IndexError, 'Indexing not supporting when limit < 0.'
            end
            if key.kind_of?(Range)
                return [] if key.first.nil? and key.max.nil?
                last = (key.max || key.last)
                last = last < 0 ? size+last : last
                first = key.min || key.first
                if first < 0 or last < 0
                    raise IndexError, 'Negative indexing is not supported'
                end
                if first > last
                    return []
                end
                if @cursor.first <= first and @cursor.last >= last
                    adjusted_first = first - @cursor.first
                    adjusted_last  = last - @cursor.first
                    return @results[adjusted_first..adjusted_last]
                end
                results = []
                @cursor.reset(key.min, last, 0)
                self.each do |r|
                    results << r
                end
                return results
            elsif key < 0
                raise IndexError, 'Negative indexing is not supported'
            elsif key >= size
                raise IndexError, 'Index beyond end of results'
            end

            # if Range.new(@cursor.first, @cursor.last).include?(key)
            #     adjusted_key = key - @cursor.first
            #     return @results[adjusted_key]
            # else
                @cursor.reset(key, key)
                execute
                return @results[0]
            # end
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

        # Executes a query.
        #
        # Returns the request parameters and (Hash) response.
        def execute
            _params = build_query()

            limit =
                if @limit == INT_MAX
                    @page_size
                else
                    [@page_size, @limit - offset].min
                end

            _params.merge!(:offset => offset, :limit => limit)
            SolveBio::logger.debug("execution query. from/limit: #{offset}, #{limit}")

            @response = Client.post(@data_url, _params)
            @total    = @response['total']
            SolveBio::logger.
                debug("query response took: #{@response['took']} ms, " +
                      "total: #{@total}")

            @results = @response['results']
            @cursor.reset(offset, offset + limit, 0)

            return _params, @response
        end

        def offset
            @cursor.offset_absolute
        end

        def size
            warmup('Query size')
            [@total, @limit].min
        end
        alias_method :length, :size

        # "each" must be defined in an Enumerator. Allows the Query object
        # to be an iterable. Iterates through the internal cache using a
        # cursor.
        def each(*pass)
            return self unless block_given?
            @cursor.last = size if @cursor.last == -1
            @cursor.offset = @cursor.first
            0.upto(size-1).each do |i|
                result_start = @cursor.offset
                if @cursor.has_next?
                    SolveBio::logger.debug('  Query window range: [%s...%s]' %
                                           [result_start, result_start + 1])
                else
                    SolveBio::logger.debug('executing query. offset/limit: %6d/%d' %
                                           [i, @limit])
                    execute()
                    # ?? Should we doublecheck execute status?
                    result_start = @cursor.offset
                end
                @cursor.advance
                yield @results[result_start]
            end
            return self
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
