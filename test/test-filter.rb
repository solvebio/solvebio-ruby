#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/filter'

class TestFilter < Test::Unit::TestCase

    def test_filter
        f = SolveBio::Filter.new
        assert_equal('<Filter []>', f.inspect, 'empty filter')
        assert_equal('<Filter []>', (~f).inspect, '"not" of empty filter')
        f2 = SolveBio::Filter.new({:style => 'Mexican', :price => 'Free'})
        assert_equal('<Filter [{:and=>[[:price, "Free"], [:style, "Mexican"]]}]>',
                     f2.inspect, 'Hash to tuple sorting'
                     )
        assert_equal('<Filter [{:not=>{:and=>[[:price, "Free"], [:style, "Mexican"]]}}]>',
                     (~f2).inspect, '~ of a non-nil filter')
        assert_equal('<Filter [{:and=>[[:price, "Free"], [:style, "Mexican"]]}]>',
                     (~~f2).inspect, '~~ has no effect')

    end

    def test_process_filters
        # FIXME: add more and put in a loop.
        filters = [[:omid, nil]]
        expect  = filters
        assert_equal(expect.inspect,
                     SolveBio::Filter.process_filters(filters).inspect)
    end

end
