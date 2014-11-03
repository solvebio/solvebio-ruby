#!/usr/bin/env ruby
$VERBOSE = true
require 'socket'
require_relative 'helper'
require_relative '../lib/resource/main'

class TestQueryBatch < Test::Unit::TestCase

    if SolveBio::api_key and not local_api?

        def setup
            begin
                @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            rescue SocketError
                @dataset = nil
            end
        end

        def test_invalid_batch_query
            skip('Are you connected to the Internet?') unless @dataset
            assert_raise SolveBio::Error do
                SolveBio::BatchQuery
                    .new([
                          @dataset.query(:limit => 1, :fields => [:bogus_field]),
                          @dataset.query(:limit => 10).filter(:bogus_id__gt => 100000)
                         ]).execute
            end

            dataset2 = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')
            results = SolveBio::BatchQuery
                .new([
                      dataset2.query(:limit => 1),
                      @dataset.query(:limit => 10).filter(:hgnc_id__gt => 100)
                     ]).execute
            assert_equal(2, results.length)

        end

        def test_batch_query
            skip('Are you connected to the Internet?') unless @dataset
            queries = [
                       @dataset.query(:limit => 1),
                       @dataset.query(:limit => 10).filter(:hgnc_id__gt => 100)
                      ]
            results = SolveBio::BatchQuery.new(queries).execute
            assert_equal(2, results.size)
            assert_equal(1, results[0]['results'].length)
            assert_equal(10, results[1]['results'].size)
        end


    else
        def test_skip
            if SolveBio::api_key
                skip "Dataset #{TEST_DATASET_NAME} not available"
            else
                skip 'Please set SolveBio::api_key'
            end
        end
    end

end
