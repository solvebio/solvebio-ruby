# -*- coding: utf-8 -*-
require 'pp'
require_relative 'client'
require_relative 'filter'

#from .utils.printing import pretty_int
#from .utils.tabulate import tabulate

# A Query API request wrapper that generates a request from Filter
# objects, and can iterate through streaming result sets.
class SolveBio::PagingQuery

    include Enumerable

    MAXIMUM_LIMIT ||= 100

    attr_reader :total
    attr_accessor :filters

    def initialize(dataset_id, params={})
        @dataset_id = dataset_id
        @data_url = "/v1/datasets/#{dataset_id}/data"

        @total = @results = @response = nil
        reset_range_window

        # results per request
        @limit = Integer(params[:limit]) rescue MAXIMUM_LIMIT
        @result_class = params[:result_class] || Hash
        @debug = params[:debug] || false
        @fields = params[:fields]
        @filters = []

        # parameter error checking
        if @limit < 0
            raise Exception, "'limit' parameter must be >= 0"
        end
        self
    end

    def clone(filters=nil)
        result =
            initialize(@dataset_id,
                       {
                           :limit => @limit,
                           :result_class => @result_class,
                           :debug => @debug,
                           :fields => @fields
                       })

        result.filters << @filters

        if filters
            result.filters << filters
        end

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
    def filter(filters, kwargs={})
        return self.clone(filters + SolveBio::Filter.new(kwargs).filters)
    end

    # Shortcut to do range queries on supported datasets.
    def range(chromosome, start, last, strand=nil, overlap=true)
        # TODO: ensure dataset supports range queries?
        return self.
            clone([self.new(chromosome, start, last, strand, overlap)])
    end

    # Takes a list of filters and returns JSON
    #
    #    :arg filters: list of Filters, (key, val) tuples, or dicts
    #
    #    :returns: list of JSON API filters
    def process_filters(filters)
        rv = []
        filters.each do |f|
            if f.kind_of?(SolveBio::Filter)
                if f.filters
                    rv << process_filters(f.filters)
                    next
                end
            elsif f.kind_of?(Hash)
                key = f.keys()[0]
                val = f[key]

                if val.kind_of?(Hash)
                    filter_filters = process_filters(val)
                    if filter_filters.size == 1
                        filter_filters = filter_filters[0]
                    end
                    rv << {key => filter_filters}
                else
                    rv << {key => process_filters(val)}
                end
            else
                rv << [f]
            end
        end
        return rv
    end

    def size
        warmup('PagingQuery size')
        return @total
    end

    def empty?
        warmup('empty?')
        return @total == 0
    end

    def inspect
        if @total == 0 or @limit == 0
            return 'query returned 0 results'
        end

        # msg = "\n%s\n\n... %s more results." % [
        #                                         tabulate(self[0].items(),
        #                                                  ['Fields', 'Data'],
        #                                                  ['right', 'left']),
        #                                         pretty_int(@total - 1)]
        msg = "\n#{self[0].pretty_inspect}\n\n... #{@total-1} more results."
        return msg
    end

    # warmup result set...
    def warmup(what)
        unless @response
            SolveBio::logger.debug("warmup #{what}")
            execute
        end
    end


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
        @request_range = self.to_range(key)

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
                @results[(0..key.end - key.begin)]
            else
                @results[0]
            end
        # reset request range
        @request_range = (0..Float::INFINITY)
        return result
    end

    # "each" must be defined in an Enumerator. Allows the Query object to be
    # an iterable.
    def each(*pass)
        return self unless block_given?
        i = 0
        while i < @total and i < @delta
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
            filters = process_filters(@filters)
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
        _params.merge(params)
        SolveBio::logger.debug("querying dataset: #{_params}")

        @response = SolveBio::Client.client.request('post', @data_url, _params)
        @total    = @response['total']
        SolveBio::logger.
            debug("query response took: #{@response['took']} ms, " +
                  "total: #{@total}")

        # update window
        offset = _params[:offset] || 0
        @results = @response['results']
        @window = @results
        @window_range = (offset .. offset + @results.size)

        return _params, @response
    end
end

class SolveBio::Query < SolveBio::PagingQuery
    def initialize(dataset_id, params={})
        super
        return self
    end

    def size
        warmup('Query size')
        [@total, @results.size].min
    end

    # "each" must be defined in an Enumerator. Allows the Query object to be
    # an iterable.
    def each(*pass)
        return self unless block_given?
        i = 0
        while i < @total and i < @limit
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
        # FIXME: Dunno why above isn't enough.
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
            q.merge({:dataset => i._dataset_id})
            query[:queries] << q
        end

        return query
    end

    def execute(params={})
        _params = build_query()
        _params.merge(params)
        response = SolveBio::Client.
            client.request('post', '/v1/batch_query', _params)
        return response
    end
end

# Demo/test code
if __FILE__ == $0
    if SolveBio::api_key
        test_dataset_name = 'omim/0.0.1-1/omim'
        require_relative 'solvebio'
        require_relative 'errors'
        dataset = SolveBio::Dataset.retrieve(test_dataset_name)
        limit = 5
        results = dataset.query({:limit => limit, :paging =>false})
        puts results.size
        results.each_with_index { |val, i|
            puts val.size
            # require 'trepanning'; debugger if i == 0
        }
        puts results[limit-1]
        results = dataset.query({:limit => limit, :paging=>true})
        puts results.size
    else
        puts 'Set SolveBio::api_key to run demo'
    end
end
