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


end
