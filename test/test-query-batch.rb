#!/usr/bin/env ruby
$VERBOSE = true
require 'socket'
require_relative 'helper'
require_relative '../lib/resource/main'

class TestQueryBatch < Test::Unit::TestCase
    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    def test_invalid_batch_query
        assert_raise SolveBio::Error do
            SolveBio::BatchQuery
                .new([
                      @dataset.query(:limit => 1, :fields => [:bogus_field]),
                      @dataset.query(:limit => 10).filter(:bogus_id__gt => 100000)
                     ]).execute
        end

        results = SolveBio::BatchQuery
            .new([
                  @dataset.query(:limit => 10).filter(:hgnc_id__lt => 100),
                  @dataset.query(:limit => 10).filter(:hgnc_id__gt => 100)
                 ]).execute
        assert_equal(2, results.length)

    end

    def test_batch_query
        queries = [
                   @dataset.query(:limit => 1),
                   @dataset.query(:limit => 10).filter(:hgnc_id__gt => 100)
                  ]
        results = SolveBio::BatchQuery.new(queries).execute
        assert_equal(2, results.size)
        assert_equal(1, results[0]['results'].length)
        assert_equal(10, results[1]['results'].size)
    end
end
