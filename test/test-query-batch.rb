#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQueryBatch < Test::Unit::TestCase

    TEST_DATASET_NAME = 'ClinVar/2.0.0-1/Variants'

    if SolveBio::api_key

        def setup
            @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        end

        def test_invalid_batch_query
            assert_raise SolveBio::Error do
                SolveBio::BatchQuery
                    .new([
                          @dataset.query(:limit => 1, :fields => [:bogus_field]),
                          @dataset.query(:limit => 10).filter(:hg19_start__gt => 100000)
                         ]).execute
            end

            dataset2 = SolveBio::Dataset.retrieve('HGNC/1.0.0-1/HGNC')
            results = SolveBio::BatchQuery
                .new([
                      dataset2.query(:limit => 1),
                      @dataset.query(:limit => 10).filter(:hg19_start => 100000)
                     ]).execute
            assert_equal(2, results.size)



        end

        def test_batch_query
            queries = [
                       @dataset.query(:limit => 1),
                       @dataset.query(:limit => 10).filter(:hg19_start__gt => 100000)
                      ]
            results = SolveBio::BatchQuery.new(queries).execute
            assert_equal(2, results.size)
            assert_equal(1, results[0]['results'].size)
            assert_equal(10, results[1]['results'].size)
        end


    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
