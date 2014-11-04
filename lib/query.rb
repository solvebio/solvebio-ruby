# -*- coding: utf-8 -*-
require 'pp'
require_relative 'client'
require_relative 'filter'
require_relative 'locale'
require_relative 'tabulate'

# A Query API request wrapper that generates a request from Filter
# objects, and can iterate through streaming result sets.
class SolveBio::PagingQuery

    include Enumerable

    MAXIMUM_LIMIT ||= 100

    attr_accessor :filters
    attr_reader   :dataset_id

    def initialize(dataset_id, params={})
        @dataset_id = dataset_id

        begin
            @limit = Integer(dataset_id)
        rescue
            raise TypeError, "'dataset_id' parameter must an Integer"
        end

        @data_url = "/v1/datasets/#{dataset_id}/data"

        @total = @results = @response = nil
        reset_range_window

        # results per request
        @limit = MAXIMUM_LIMIT
        begin
            @limit = Integer(params[:limit])
        rescue
            raise TypeError, "'limit' parameter must an Integer >= 0"
        end if params.member?(:limit)

        @result_class = params[:result_class] || Hash
        @debug = params[:debug] || false
        @fields = params[:fields]
        @filters = []

        # parameter error checking
        if @limit < 0
            raise RangeError, "'limit' parameter must be >= 0"
        end
        self
    end

    def total
        warmup('Query total')
        @total = @response["total"]
    end

    def clone(filters=[])
        result =
            initialize(@dataset_id,
                       {
                           :limit => @limit,
                           :total => total,  # This causes an HTTP request
                           :result_class => @result_class,
                           :debug => @debug,
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
        if filters.kind_of?(SolveBio::Filter)
            return Marshal.load(Marshal.dump(params.filters))
        else
            return clone(SolveBio::Filter.new(params, conn).filters)
        end
    end

    # Shortcut to do range queries on supported datasets.
    def range(chromosome, start, last, strand=nil, overlap=true)
        # TODO: ensure dataset supports range queries?
        return self.
            clone([self.new(chromosome, start, last, strand, overlap)])
    end

    def size
        warmup('PagingQuery size')
        return @total
    end
    alias_method :length, :size

    def empty?
        warmup('empty?')
        return @total == 0
    end

    # Convert SolveBio::QueryPaging object to a String type
    def to_s
        if total == 0 or @limit == 0
            return 'query returned 0 results'
        end

        sorted_items = SolveBio::Tabulate.
            tabulate(self[0].to_a.sort_by{|x| x[0]})
        msg =
            "\n%s\n\n... %s more results." %
            [sorted_items, ['Fields', 'Data'], ['right', 'left'],
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
        return '<%s: @dataset_id=%s, @total=%s, @limit=%s, @debug=%s>' %
            [self.class, @dataset_id, @total ? @total : '?',
             @limit, @debug]
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
            if key.begin < 0 or key.end < 0
                raise IndexError, 'Negative indexing is not supported'
            end
            if key.begin > key.end
                raise IndexError, 'Backwards indexing is not supported'
            end
        elsif key < 0
            raise IndexError, 'Negative indexing is not supported'
        end

        # FIXME: is it right that we can assume that the results are in
        # @results. Do I need another index check?

        result =
            if key.kind_of?(Range)
                @results[(0...key.end - key.begin)]
            else
                @request_range = self.to_range(key)
                @results[0]
            end
        # reset request range
        @request_range = (0..Float::INFINITY)
        return result
    end

    # "each" must be defined in an Enumerator. Allows the Query object
    # to be an iterable. Iterates through the internal cache using a
    # cursor.
    def each(*pass)
        return self unless block_given?
        i = 0

        @delta = @request_range.end - @request_range.begin
        while i < total and i < @delta
            i_offset = i + @request_range.begin
            if @window_range.include?(i_offset)
                result_start = i_offset - @window_range.begin
                SolveBio::logger.debug('  PagingQuery window range: [%s...%s]' %
                                       [result_start, result_start + 1])
            else
                SolveBio::logger.debug('executing query. offset/limit: %6d/%d' %
                                       [i_offset, @limit])
                execute({:offset => i_offset, :limit => @limit})
                result_start = i % @limit
            end
            yield @results[result_start]
            @delta = @request_range.end - @request_range.begin
            i += 1
        end
        return self
    end

    # range operations
    def to_range(range_or_idx)
        return range_or_idx.kind_of?(Range) ? range_or_idx :
            (range_or_idx..range_or_idx + 1)
    end

    def reset_request_range
        @request_range = (0..Float::INFINITY)
    end

    def reset_range_window
        @window = []
        @window_range = (0..Float::INFINITY)
        reset_request_range
    end

    def build_query
        q = {
            :limit => @limit,
            :debug => @debug
        }

        if @filters
            filters = SolveBio::Filter.process_filters(@filters)
            if filters.size > 1
                q[:filters] = [{:and => filters}]
            else
                q[:filters] = filters
            end
        end

        if @fields
            q[:fields] = @fields
        end

        return q
    end

    # Executes a query and returns the request parameters and response.
    def execute(params={})
        _params = build_query()
        _params.merge!(params)
        SolveBio::logger.debug("querying dataset: #{_params}")

        @response = SolveBio::Client.client.post(@data_url, _params)
        @total    = @response['total']
        SolveBio::logger.
            debug("query response took: #{@response['took']} ms, " +
                  "total: #{@total}")

        # update window
        offset = _params[:offset] || 0
        @results = @response['results']
        @window = @results
        @window_range = (offset ... offset + @results.size)

        return _params, @response
    end
end

class SolveBio::Query < SolveBio::PagingQuery
    def initialize(dataset_id, params={})
        super
        return self
    end

    def total
        warmup('Query total')
        @total
    end

    def size
        warmup('Query size')
        [@total, @results.size].min
    end
    alias_method :length, :size

    # "each" must be defined in an Enumerator. Allows the Query object
    # to be an iterable. Iterates through the internal cache using a
    # cursor.
    def each(*pass)
        return self unless block_given?
        i = 0
        while i < size and i < @limit
            i_offset = i + @request_range.begin
            if @window_range.include?(i_offset)
                result_start = i_offset - @window_range.begin
                SolveBio::logger.debug('  Query window range: [%s...%s]' %
                                       [result_start, result_start + 1])
            else
                SolveBio::logger.debug('executing query. offset/limit: %6d/%d' %
                                       [i_offset, @limit])
                execute({:offset => i_offset, :limit => @limit})
                result_start = i % @limit
            end
            yield @results[result_start]
            i += 1
        end
        return self
    end

    def [](key)
        # Note: super does other parameter checks.
        if key.kind_of?(Fixnum) and key >= @window_range.end
            raise IndexError, "Invalid index #{key} >= #{@window_range.end}"
        end
        super[key]
        # FIXME: Dunno why the above isn't enough.
        @results[key]
    end
end


# BatchQuery accepts a list of Query objects and executes them
# in a single request to /v1/batch_query.
class SolveBio::BatchQuery
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
            q.merge!(:dataset => i.dataset_id)
            query[:queries] << q
        end

        return query
    end

    def execute(params={})
        _params = build_query()
        _params.merge!(params)
        response = SolveBio::Client.client.post('/v1/batch_query', _params)
        return response
    end
end

# Demo/test code
if __FILE__ == $0
    if SolveBio::api_key
        test_dataset_name = 'ClinVar/2.0.0-1/Variants'
        require_relative 'solvebio'
        require_relative 'errors'
        dataset = SolveBio::Dataset.retrieve(test_dataset_name)

        # # A filter
        # limit = 5
        # results = dataset.query({:paging=>false, :limit => limit}).
        #         filter({:alternate_alleles => nil})
        # puts results.size

        limit = 2
        # results = dataset.query({:limit => limit, :paging =>false})
        # puts results.size
        # results.each_with_index { |val, i|
        #     puts "#{i}: #{val}"
        # }
        # puts "#{limit-1}: #{results[limit-1]}"
        results = dataset.query({:limit => limit, :paging=>true})
        # puts results.size
        puts results.to_s
    else
        puts 'Set SolveBio::api_key to run demo'
    end
end
