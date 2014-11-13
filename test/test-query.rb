$VERBOSE = true
require_relative 'helper'
require_relative '../lib/resource/main'

class TestQuery < Test::Unit::TestCase
    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    # When paging is off, results.length should return the number of
    # results retrieved.
    def test_basic
        results = @dataset.query()
        assert_equal(results.total, results.size)
        assert_equal(results.total, results.length)
    end

    # results.size should return the number of
    # results retrieved.
    def test_basic_with_limit
        limit = 100
        results = @dataset.query(:limit=>limit)
        assert_equal(results.size, limit)
        assert_raise IndexError do
            results[results.total + 1]
        end
    end

    def test_count
        q = @dataset.query
        total = q.count
        assert_operator total, :>, 0

        # with a filter
        q = @dataset.query.filter(:omim_ids => 123631)
        assert_equal(1, q.count)

        # with a bogus filter
        q = @dataset.query.filter(:omim_ids => 999999)
        assert_equal(0, q.count)
    end

    def test_count_with_limit
        q = @dataset.query
        total = q.count
        assert_operator total, :>, 0

        [0, 10, 1000].each do |limit|
            # with a filter
            q = @dataset.query(:limit => limit).filter(:omim_ids => 123631)
            assert_equal(1, q.count)

            # with a bogus filter
            q = @dataset.query(:limit => limit).filter(:omim_ids => 999999)
            assert_equal(0, q.count)
        end
    end

    def test_len
        q = @dataset.query
        total = q.count
        assert_operator total, :>, 0
        assert_equal total, q.size

        # with a filter
        q = @dataset.query.filter(:omim_ids => 123631)
        assert_equal 1, q.size

        # with a bogus filter
        q = @dataset.query.filter(:omim_ids => 999999)
        assert_equal 0, q.size
    end

    def test_len_with_limit
        q = @dataset.query
        total = q.count
        assert_operator total, :>, 0
        assert_equal total, q.size

        [0, 10, 1000].each do |limit|
            # with a filter
            q = @dataset.query(:limit => limit).filter(:omim_ids => 123631)
            assert_equal(limit > 0 ? 1 : 0, q.size)

            # with a bogus filter
            q = @dataset.query(:limit => limit).filter(:omim_ids => 999999)
            assert_equal 0, q.size
        end
    end

    # test Query when limit is specified and is GREATER THAN total available
    # results.
    def test_empty
        # bogus filter
        results = @dataset.query.filter(:omim_ids => 999999)
        assert_equal(0, results.size)
        assert_equal(results[0...results.size], [])
        assert_raise IndexError do
            results[0]
        end
    end


    # test Query when limit is specified and is GREATER THAN total available
    #    results.
    def test_empty_with_limit
        limit = 100
        # bogus filter
        results = @dataset.query(:limit => limit)
                    .filter(:omim_ids => 999999)
        assert_equal 0, results.size
        assert_equal(results[0...results.size], [])
        assert_raise IndexError do
            results[0]
        end
    end

end
