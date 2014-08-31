#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQuery < Test::Unit::TestCase

    TEST_DATASET_NAME = 'omim/0.0.1-1/omim'

    def test_query
        if SolveBio::api_key
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            results = dataset.query({:paging=>true, :limit => 10})
            # When paging is on, results.size should return the number
            # of total number of results.
            assert_equal(results.size, results.total,
                         'results.size == results.total, paging=true')
        else
            skip('Please set SolveBio::api_key')
        end
    end

    # When paging is off, results.size should return the number of
    # results retrieved.
    def test_limit
        if SolveBio::api_key
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            limit = 10
            results = dataset.query({:paging=>false, :limit => limit})
            assert_equal(results.size, limit,
                         'results.size == limit, paging = false')


            results.each_with_index do |val, i|
                assert results[i], "retrieving value at #{i}"
            end

            assert_raise IndexError do
                puts results[limit]
            end

        else
            skip('Please set SolveBio::api_key')
        end
    end
end
