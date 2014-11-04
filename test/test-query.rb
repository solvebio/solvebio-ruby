$VERBOSE = true
require 'socket'
require_relative 'helper'
require_relative '../lib/resource/main'

class TestQuery < Test::Unit::TestCase
    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    # When paging is off, results.length should return the number of
    # results retrieved.
    def test_limit
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        limit = 10
        results = @dataset.query :paging=>false, :limit => limit
        assert_equal(limit, results.length,
                     'limit == results.size, paging = false')


        results.each_with_index do |val, i|
            assert results[i], "retrieving value at #{i}"
        end

        assert_raise IndexError do
            puts results[limit]
        end
    end

    # test Query when limit is specified and is GREATER THAN total available
    #  results
    def test_limit_empty
        limit = 100
        results = @dataset.query(:paging=>false, :limit => limit).
            filter({:omim_ids => 999999})
        assert_equal(0, results.size)

        assert_raise IndexError do
            puts results[0]
        end

        results = @dataset.query(:paging=>false, :limit => limit).
            filter :omim_ids => 123631
        assert_equal(1, results.size)
    end

    # test Filtered Query in which limit is specified but is GREATER THAN
    #  the number of total available results
    def test_limit_filter
        limit = 10
        num_filters = 2

        filters =
            SolveBio::Filter.new(:omim_ids => 123631) |
            SolveBio::Filter.new(:omim_ids => 123670)

        results = @dataset.query(:paging=>false, :limit => limit,
                                 :filters => filters)

        num_filters.times do |i|
            assert results[i]
        end

        assert_equal(num_filters, results.size)

        assert_raise IndexError do
            puts results[num_filters]
        end
    end

end
