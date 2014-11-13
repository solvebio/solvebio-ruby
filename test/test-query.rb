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

    # test Filtered Query in which limit is specified but is GREATER THAN
    #    the number of total available results
    def test_filter
        num_filters = 4
        filters =
            SolveBio::Filter.new(:omim_ids => 123631) |
            SolveBio::Filter.new(:omim_ids => 123670) |
            SolveBio::Filter.new(:omim_ids => 123690) |
            SolveBio::Filter.new(:omim_ids => 306250)
        results = @dataset.query :filters => filters
        assert_equal num_filters, results.size
        assert_raise IndexError do
            results[num_filters]
        end
    end

    #   test SolveBio::Filtered Query in which limit is specified but is GREATER THAN
    #    the number of total available results
    def test_filter_with_limit
        limit = 10
        num_filters = 4
        filters =
            SolveBio::Filter.new(:omim_ids => 123631) |
            SolveBio::Filter.new(:omim_ids => 123670) |
            SolveBio::Filter.new(:omim_ids => 123690) |
            SolveBio::Filter.new(:omim_ids => 306250)
        results = @dataset.query :limit => limit, :filters => filters
        assert_equal num_filters, results.size
        assert_raise IndexError do
            results[num_filters]
        end
    end

    def test_paging
        page_size = 10
        num_pages = 3
        results = @dataset.query :page_size => page_size

        _results = []
        results.each_with_index.each do |r, i|
            # break after fetching num_pages
            break if i / page_size == num_pages
            _results << r
        end

        assert_equal _results.size, num_pages * page_size
        assert_equal num_pages * page_size, _results.map{|i| i}.size
    end

    def test_paging_with_limit
        page_size = 10
        num_pages = 3
        limit = num_pages * page_size - 1
        results = @dataset.query(:limit => limit, :page_size => page_size)

        _results = []
        results.each_with_index.each do |r, i|
            _results << r
        end

        assert_equal _results.size, limit
        assert_equal limit, _results.map{|i| i}.size
    end

    def test_slice_ranges
        limit = 50

        results = @dataset.query :limit => limit
        assert_equal limit, results[0..limit].size
        assert_equal results[limit..limit].size, 0
        assert_equal results[limit..-1].size, 0

        r0 = @dataset.query(:limit => limit)[0..limit][-1]
        r1 = @dataset.query(:limit => limit)[limit-1..-1][0]
        assert_equal(r0['hgnc_id'], r1['hgnc_id'])
    end

    # def test_slice_ranges_with_paging
    #     limit = 50
    #     page_size = 10

    #     require 'trepanning'; debugger
    #     results = @dataset.query(:limit => limit, :page_size => page_size)
    #     assert_equal results[0..limit].size, limit

    #     results = @dataset.query(:limit => limit, :page_size => page_size)
    #     assert_equal results[limit..limit].size, 0

    #     r0 = @dataset.query(:limit => limit)[0..limit][-1]
    #     r1 = @dataset.query(:limit => limit)[limit-1..-1][0]
    #     assert_equal(r0['hgnc_id'], r1['hgnc_id'])
    # end

    # def test_slice_ranges_with_small_limit
    #     # Test slices larger than 'limit'
    #     limit = 1
    #     results = @dataset.query(:limit => limit) \
    #         .filter(hgnc_id__range=(1000, 2000))[0:4]
    #     assert_equal(results), limit.size
    # end

    # def _query()
    #         return @dataset.query(limit=10) \
    #                   .filter(hgnc_id__range=(1000, 5000))
    # end

    # def test_paging_and_slice_equivalence
    #     idx0 = 3
    #     idx1 = 5

    #     results_slice = _query()[idx0:idx1]
    #     results_paging = []

    #     for (i, r) in enumerate(_query()):
    #         if i == idx1
    #             break
    #         elsif i >= idx0
    #                       results_paging << r
    #         end
    #     end

    #     assert_equal(results_paging), results_slice.size.size

    #     for i in range(0, results_slice).size:
    #         id_a = results_paging[i]['hgnc_id']
    #         id_b = results_slice[i]['hgnc_id']
    #         assert_equal(id_a, id_b)
    #     end

    # def test_caching
    #     idx0 = 60
    #     idx1 = 81

    #     q = @dataset.query(limit=100)
    #     results_slice = q[idx0:idx1]
    #     results_cached = q[idx0:idx1]
    #     assert_equal(results_slice), len(results_cached).size
    #     for i in range(0, results_slice).size:
    #         id_a = results_slice[i]['chromosome']
    #         id_b = results_cached[i]['chromosome']
    #         assert_equal(id_a, id_b)
    #     end
    # end

    # def test_get_by_index
    #     limit = 100
    #     page_size = 10
    #     idxs = [0, 1, 10, 20, 50, 99]
    #     q = @dataset.query(:limit => limit, :page_size => page_size)
    #     cached = []
    #     for idx in idxs:
    #                    cached << q[idx]
    #     end

    #     # forwards
    #     for (i, idx) in enumerate(idxs):
    #            assert_equal(cached[i], q[idx])
    #     end

    #     # backwards
    #     for (i, idx) in reversed(list(enumerate(idxs))):
    #            assert_equal(cached[i], q[idx])
    #     end
    # end

end
