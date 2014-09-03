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
            limit = 100
            total = 4
            results = @dataset.query(:paging => true, :limit => limit).
                    filter(:omim_id__in => (100000..100200).to_a)

            ## FIXME: is this right?
            assert_equal(total, results.size)

            i = 0
            results.each do
                i += 1
            end
            ## FIXME: is this right?
            assert_equal(i, total)
            skip('Reconcile difference in total with Python client')
        end


        def test_slice
            limit = 100
            results = @dataset.query(:paging => true, :limit => limit).
                filter(:omim_id__in => (100000...100200).to_a)[10...20]
            assert_equal(3, results.size)

            results = @dataset.query(:paging => true, :limit => limit).
                filter(:omim_id__in => (100000...100200).to_a)[0...3]
            ## FIXME: is this right?
            assert_equal(3, results.size)
            skip 'Reconcile with Python Client'
        end

    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
