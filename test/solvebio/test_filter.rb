require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestFilter < Test::Unit::TestCase
        def test_filter_errors
            assert_raises TypeError do
                SolveBio::Filter.new(:style__gtt => 5)
            end
            assert_raises TypeError do
                SolveBio::Filter.new(:style__range => 'a')
            end
            assert_raises TypeError do
                SolveBio::Filter.new(:style__range => [5,10,15])
            end
            assert_raises IndexError do
                SolveBio::Filter.new(:style__range => [10,5])
            end
        end

        def test_filter
            f = SolveBio::Filter.new
            assert_equal('<SolveBio::Filter []>', f.inspect, 'empty filter')
            assert_equal('<SolveBio::Filter []>',
                         (~f).inspect, '"not" of empty filter')
            f2 = SolveBio::Filter.new({:style => 'Mexican', :price => 'Free'})
            assert_equal('<SolveBio::Filter [{:and=>[[:price, "Free"], [:style, "Mexican"]]}]>',
                         f2.inspect, 'Hash to tuple sorting'
                         )
            assert_equal('<SolveBio::Filter [{:not=>{:and=>[[:price, "Free"], [:style, "Mexican"]]}}]>',
                         (~f2).inspect, '~ of a non-nil filter')
            assert_equal('<SolveBio::Filter [{:and=>[[:price, "Free"], [:style, "Mexican"]]}]>',
                         (~~f2).inspect, '~~ has no effect')

            filters3 =
                SolveBio::Filter.new(:omim_id => 144650) |
                SolveBio::Filter.new(:omim_id => 144600) |
                SolveBio::Filter.new(:omim_id => 145300)

            assert_equal('<SolveBio::Filter [{:or=>[[:omim_id, 144650], [:omim_id, 144600], [:omim_id, 145300]]}]>',
                         filters3.inspect,
                         'combining more than one of a connector (|)')

            assert_equal('<SolveBio::Filter [[:style__range, [5, 10]]]>',
                         SolveBio::Filter.new(:style__range => (5...11)).inspect)
            assert_equal('<SolveBio::Filter [[:style__range, [5, 10]]]>',
                         SolveBio::Filter.new(:style__range => (5..10)).inspect)

        end

        def test_genomic_filter
            assert_equal(
                '<GenomicFilter [{:and=>[["genomic_coordinates.start", 32200000], ["genomic_coordinates.stop", 32500000], ["genomic_coordinates.chromosome", "13"]]}]>',
                         SolveBio::GenomicFilter.
                         new("13", 32200000, 32500000, exact: true).inspect)
        end

        def test_process_filters
            # FIXME: add more and put in a loop.
            filters = [[:omid_id, nil]]
            expect  = filters
            assert_equal(expect.inspect,
                         SolveBio::Filter.process_filters(filters).inspect)
        end

        def test_genomic_single_position
            f = SolveBio::GenomicFilter.new('chr1', 100)
            assert_equal(
                '<GenomicFilter [{:and=>[["genomic_coordinates.start__lte", 100.0], ["genomic_coordinates.stop__gte", 100.0], ["genomic_coordinates.chromosome", "1"]]}]>',
                f.inspect)

            f = SolveBio::GenomicFilter.new('chr1', 100, 100, true)
            assert_equal(
                '<GenomicFilter [{:and=>[["genomic_coordinates.start", 100], ["genomic_coordinates.stop", 100], ["genomic_coordinates.chromosome", "1"]]}]>',
                f.inspect)
        end

        def test_range
            f = SolveBio::GenomicFilter.new('chr1', 100, 200)
            assert_equal('<GenomicFilter [{:and=>[{:or=>[{:and=>[["genomic_coordinates.start__lte", 100.0], ["genomic_coordinates.stop__gte", 200.0]]}, ["genomic_coordinates.start__range", [100, 200]], ["genomic_coordinates.stop__range", [100, 200]]]}, ["genomic_coordinates.chromosome", "1"]]}]>',
                         f.inspect)
            f = SolveBio::GenomicFilter.new('chr1', 100, 200, true)
            assert_equal('<GenomicFilter [{:and=>[["genomic_coordinates.start", 100], ["genomic_coordinates.stop", 200], ["genomic_coordinates.chromosome", "1"]]}]>',
                         f.inspect)
        end
    end
end
