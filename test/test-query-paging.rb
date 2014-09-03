#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQueryPaging < Test::Unit::TestCase

    TEST_DATASET_NAME = 'omim/0.0.1-1/omim'

    if SolveBio::api_key

        def setup
            @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        end

        def test_query
            results = @dataset.query(:paging=>true, :limit => 10)
            # When paging is on, results.size should return the number
            # of total number of results.
            assert_equal(results.size, results.total,
                         'results.size == results.total, paging=true')
        end

        # In paging queries, results.size should return the total number of
        # results that exist. Yes, this is the same as test_query, but
        # we revers the order of access, to make sure "warmup" is called.
        def test_limit
            limit = 10
            results = @dataset.query(:paging=>true, :limit => limit)
            assert_equal(results.total, results.size,
                         'results.total == results.size, paging = true')
        end


        def test_paging
            skip 'Fix up range (paging)'
            limit = 100
            total = 823
            results = @dataset.query(:paging => true, :limit => limit).
                    filter(:omim_id__in => [100000...120000].to_a)

            assert_equal(results.size, total)

            i = 0
            results.each do
                i += 1
            end
            assert_equal(i, total - 1)
        end


        #### FIXME: figure out how to reinstate
        def test_slice
            skip 'Fix up range (slice)'
            limit = 100
            results = @dataset.query(:paging => true, :limit => limit).
                filter(:omim_id__in => [100000...120000].to_a)[200...410]
            assert_equal(210, results.size)

            results = @dataset.query(:paging => true, :limit => limit).
                filter(:omim_id__in => [100000...110000].to_a)[0...5]
            assert_equal(5, results.size)
        end

    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
