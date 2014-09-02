#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestQueryBatch < Test::Unit::TestCase

    TEST_DATASET_NAME = 'omim/0.0.1-1/omim'

    if SolveBio::api_key

        def setup
            @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        end

        def test_invalid_batch_query
            assert_raise SolveBio::Error do
                SolveBio::BatchQuery
                    .new([
                          @dataset.query(:limit => 1, :fields => [:bogus_field]),
                          @dataset.query(:limit => 10).filter(:omim_id__gt => 100000)
                         ]).execute
            end

            assert_raise SolveBio::Error do
                dataset2 = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')
                SolveBio::BatchQuery
                    .new([
                          dataset2.query(:limit => 1),
                          @dataset.query(:limit => 10).filter(:omim_id__gt => 100000)
                         ]).execute
            end

        end

        def test_batch_query
            queries = [
                       @dataset.query(:limit => 1),
                       @dataset.query(:limit => 10).filter(:omim_id__gt => 100000)
                      ]
            results = SolveBio::BatchQuery.new(queries).execute
            assert_equal(results.size, 2)
            assert_equal(results[0]['results'].size, 1)
            assert_equal(results[1]['results'].size, 10)
        end


    else
        def test_skip
            skip 'Please set SolveBio::api_key'
        end
    end

end
