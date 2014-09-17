#!/usr/bin/env ruby
require_relative '../lib/tabulate'
$VERBOSE = true
require 'test/unit'

class TestTabulate < Test::Unit::TestCase

    include SolveBio::Tabulate

    def test_classify

        assert_equal number?("123.45"), true
        assert_equal number?("123"), true
        assert_equal number?("spam"), false
        assert_equal int?("123"), true
        assert_equal int?('124.45'), false

        assert_equal _type(nil),  TYPES[:none_type]
        assert_equal _type('foo'), TYPES[:text_type]
        assert_equal  _type('1'), TYPES[:int]
        assert_equal _type('\x1b[31m42\x1b[0m'), TYPES[:int]
    end

    def test_align
        assert_equal( 2, afterpoint('123.45'))
        assert_equal(-1, afterpoint('1001'))
        assert_equal(-1, afterpoint("eggs"))
        assert_equal( 2, afterpoint("123e45"))

        assert_equal("  \u044f\u0439\u0446\u0430",
                     padleft(6, "\u044f\u0439\u0446\u0430"))
        assert_equal("\u044f\u0439\u0446\u0430  ",
                     padright(6, "\u044f\u0439\u0446\u0430"))

        assert_equal(" \u044f\u0439\u0446\u0430 ",
                     padboth(6, "\u044f\u0439\u0446\u0430"))

        assert_equal(" \u044f\u0439\u0446\u0430  ",
                     padboth(7, "\u044f\u0439\u0446\u0430"))

        assert_equal('abc', padright(2, 'abc'))
        assert_equal('abc', padleft(2, 'abc'))
        assert_equal('abc', padboth(2, 'abc'))
    end


end
