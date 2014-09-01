#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQueryPaging < Test::Unit::TestCase

    TEST_DATASET_NAME = 'omim/0.0.1-1/omim'

    if SolveBio::api_key
        def test_query
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            results = dataset.query({:paging=>true, :limit => 10})
            # When paging is on, results.size should return the number
            # of total number of results.
            assert_equal(results.size, results.total,
                         'results.size == results.total, paging=true')
        end
    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
