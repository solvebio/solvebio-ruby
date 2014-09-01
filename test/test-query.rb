#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQuery < Test::Unit::TestCase

    TEST_DATASET_NAME = 'omim/0.0.1-1/omim'

    if SolveBio::api_key
        # When paging is off, results.size should return the number of
        # results retrieved.
        def test_limit
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            limit = 10
            results = dataset.query({:paging=>false, :limit => limit})
            assert_equal(limit, results.size,
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
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            # bogus filter
            results = dataset.query({:paging=>false, :limit => limit}).
                filter({:omim_id => nil})
            assert_equal(0, results.size)

            assert_raise IndexError do
                puts results[0]
            end
        end

        # test Filtered Query in which limit is specified but is GREATER THAN
        #  the number of total available results
        def test_limit_filter
            limit = 10
            num_filters = 3

            filters3 =
                SolveBio::Filter.new(:omim_id => 144650) |
                SolveBio::Filter.new(:omim_id => 144600) |
                SolveBio::Filter.new(:omim_id => 145300)

            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            results = dataset.query({:paging=>false, :limit => limit, :filters => filters3})

            num_filters.times do |i|
                assert results[i]
            end

            assert_equal(num_filters, results.size)

            assert_raise IndexError do
                puts results[num_filters]
            end
        end

    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
