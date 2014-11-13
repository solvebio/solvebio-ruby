#!/usr/bin/env ruby
$VERBOSE = true
require 'socket'
require_relative 'helper'
require_relative '../lib/resource/main'

class TestQueryPaging < Test::Unit::TestCase

    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    ### FIXME
    def NO_test_query
        results = @dataset.query(:paging=>true, :limit => 10)
        # When paging is on, results.size should return the number
        # of total number of results.
        assert_equal(results.size, results.total,
                     'results.size == results.total, paging=true')
    end

    #### FIXME
    # In paging queries, results.size should return the total number of
    # results that exist. Yes, this is the same as test_query, but
    # we reverse the order of access, to make sure "warmup" is called.
    def NO__test_limit
        limit = 10
        results = @dataset.query(:paging=>true, :limit => limit)
        assert_equal(results.total, results.length,
                     'results.total == results.length, paging = true')
    end

    ## FIXME
    def NO__test_paging
        limit = 100
        total = 4
        results = @dataset.query(:paging => true, :limit => limit).
            filter(:hgnc_id__in => [2396, 2404, 2409, 2411])

        assert_equal(total, results.total)

        # Make sure we can iterate over the entire result set
        i = 0
        results.each_with_index do |val, j|
            assert val, "Can retrieve filter item #{i}"
            i = j
        end
        assert_equal(i, total-1)
    end

    def test_range
        limit = 30
        results = @dataset.query(:paging => true, :limit => limit).
            filter(:hgnc_id__range => [10, 6000])[2..5]
        assert_equal(4, results.size)

        results = @dataset.query(:paging => true, :limit => limit).
            filter(:hgnc_id__range => [10, 6000])[0..7]
        assert_equal(8, results.size)
    end

    def test_paging_and_slice_equivalence
        idx0 = 3
        idx1 = 5

        query = proc{
            @dataset.query( :paging => true, :limit => 10).
            filter(:hgnc_id__range => [1000, 5000])[2..10]
        }

        results_slice = query.call()[idx0...idx1]
        results_paging = []
        query.call.each_with_index do |r, i|
            break if i == idx1
            results_paging << r if i >= idx0
        end

        assert_equal(results_slice.size, results_paging.size)

        results_paging.size.times do |i|
            id_a = results_paging[i][:hgnic_id]
            id_b = results_slice[i][:hgnc_id]
            assert_equal(id_a, id_b)
        end
    end

    def test_caching
        idx0 = 60
        idx1 = 81

        q = @dataset.query(:paging => true, :limit => 100)
        # q = self.dataset.query(paging=True, limit=100) \
        #         .filter(omim_id__in=range(100000, 120000))
        results_slice = q[idx0..idx1]
        results_cached = q[idx0..idx1]

        assert_equal(results_slice.size, results_cached.size)
        results_slice.size-1.times do |i|
            id_a = results_slice[i]['reference_allele']
            id_b = results_cached[i]['reference_allele']
            assert_equal(id_b, id_a)
        end
    end

end
