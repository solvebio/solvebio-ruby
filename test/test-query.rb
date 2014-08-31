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
            assert_equal(results.size, results.total,
                         'results.size == results.total')
        else
            skip('Please set SolveBio::api_key')
        end
    end
end
