require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestQuery < Test::Unit::TestCase
        def setup
            @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        end

        def test_basic
            results = @dataset.query.filter(:omim_ids__in => [123631, 123670, 123690, 306250])
            assert_equal(results.total, results.size)
            assert_equal(results.total, results.length)
            
            _results = []
            results.each_with_index.each do |r, i|
                _results << r
            end
            assert_equal(_results.length, results.length)
        end

        # results.size should return the number of
        # results retrieved.
        def test_basic_with_limit
            limit = 10
            results = @dataset.query(:limit => limit)
            assert_equal(results.size, limit)
            assert_equal(results[results.total + 1], nil)
            
            _results = []
            results.each_with_index.each do |r, i|
                _results << r
            end
            assert_equal(_results.length, limit)
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
            assert_operator(total, :>, 0)
            assert_equal(total, q.size)

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
            assert_equal(results[0...results.size].to_a, [])
            assert_equal(results[0], nil)
        end

        # test Query when limit is specified and is GREATER THAN total available
        #    results.
        def test_empty_with_limit
            limit = 100
            # bogus filter
            results = @dataset.query(:limit => limit)
                        .filter(:omim_ids => 999999)
            assert_equal(0, results.size)
            assert_equal(results[0...results.size].to_a, [])
            assert_equal(results[0], nil)
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
            results = @dataset.query(:filters => filters)
            assert_equal(num_filters, results.size)
            assert_equal(results[num_filters], nil)
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
            assert_equal(num_filters, results.size)
            assert_equal(results[num_filters], nil)
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

            assert_equal limit, _results.size
            assert_equal limit, _results.map{|i| i}.size
        end

        def test_slice_ranges
            limit = 50

            results = @dataset.query(:limit => limit)
            assert_equal limit, results[0..limit].size
            assert_equal 0, results[limit..limit].size
            assert_equal 0, results[limit..-1].size

            r0 = @dataset.query(:limit => limit)[0..limit][limit-1]
            r1 = @dataset.query(:limit => limit)[limit-1..limit][0]
            assert_equal(r0[:hgnc_id], r1[:hgnc_id])
        end

        def test_slice_ranges_with_paging
            limit = 5
            page_size = 2

            results = @dataset.query(:limit => limit, :page_size => page_size)[0..limit]
            assert_equal results.length, limit

            results = @dataset.query(:limit => limit, :page_size => page_size)[limit..limit-1]
            assert_equal 0, results.length, 0

            r0 = @dataset.query(:limit => limit)[0..limit][limit-1]
            r1 = @dataset.query(:limit => limit)[limit-1..limit][0]
            assert_equal(r0[:hgnc_id], r1[:hgnc_id])
        end

        def test_slice_ranges_with_small_limit
            # Test slices larger than 'limit'
            limit = 1
            results = @dataset.query(:limit => limit)
                .filter(:hgnc_id__range => [1000, 2000])[0..4]
            assert_equal limit, results.size
        end

        def hgnc_id_range_query
            @dataset.query(:limit => 10)
                .filter(:hgnc_id__range => [1000, 5000])
        end

        def test_paging_and_slice_equivalence
            idx0 = 3
            idx1 = 5

            results_slice = hgnc_id_range_query()[idx0...idx1]
            results_paging = []

            hgnc_id_range_query.each_with_index do |r,i|
                if i == idx1
                    break
                elsif i >= idx0
                    results_paging << r
                end
            end

            assert_equal results_paging.size, results_slice.size

            0.upto(results_slice.size-1).each do |i|
                id_a = results_paging[i]['hgnc_id']
                id_b = results_slice[i]['hgnc_id']
                assert_equal(id_a, id_b)
            end
        end

        def test_caching
            idx0 = 60
            idx1 = 81

            q = @dataset.query(:limit => 100)
            results_slice = q[idx0...idx1]
            results_cached = q[idx0...idx1]
            assert_equal results_cached.size, results_slice.size
            0.upto(results_slice.size-1).each do |i|
                id_a = results_slice[i]['chromosome']
                id_b = results_cached[i]['chromosome']
                assert_equal(id_a, id_b)
            end
        end

        def test_get_by_index
            limit = 100
            page_size = 10
            idxs = [0, 1, 10, 20, 50, 99]
            q = @dataset.query(:limit => limit, :page_size => page_size)
            cached = []
            idxs.each do |idx|
                cached << q[idx]
            end

            # forwards
            idxs.each_with_index do |idx, i|
                assert_equal(cached[i], q[idx])
            end

            i = cached.size - 1
            idxs.reverse.each do |idx|
                assert_equal(cached[i], q[idx])
                i -= 1
            end
        end
    end
end
