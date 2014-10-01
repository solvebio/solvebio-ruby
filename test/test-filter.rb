#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/filter'

class TestFilter < Test::Unit::TestCase

    def test_filter_errors
        assert_raises TypeError do
            SolveBio::Filter.new(:style__gtt => 5)
        end
        assert_raises TypeError do
            SolveBio::Filter.new(:style__between => 'a')
        end
        assert_raises TypeError do
            SolveBio::Filter.new(:style__between => [5,10,15])
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

        assert_equal('<SolveBio::Filter [[:style__between, [5, 10]]]>',
                     SolveBio::Filter.new(:style__between => (5...11)).inspect)
        assert_equal('<SolveBio::Filter [[:style__between, [5, 10]]]>',
                     SolveBio::Filter.new(:style__between => (5..10)).inspect)

    end

    def test_range_filter
        assert_equal('<RangeFilter [{:and=>[["hg38_start__range", ' +
                     '[32200000, 32500000]], ' +
                     '["hg38_end__range", [32200000, 32500000]], ' +
                     '["hg38_chromosome", "13"]]}]>',
                     SolveBio::RangeFilter.
                     new("hg38", "13", 32200000, 32500000).inspect)
    end

    def test_process_filters
        # FIXME: add more and put in a loop.
        filters = [[:omid, nil]]
        expect  = filters
        assert_equal(expect.inspect,
                     SolveBio::Filter.process_filters(filters).inspect)
    end

end
