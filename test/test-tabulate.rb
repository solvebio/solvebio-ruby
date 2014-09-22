#!/usr/bin/env ruby
require_relative '../lib/tabulate'
$VERBOSE = true
require 'test/unit'

class TestTabulate < Test::Unit::TestCase

    include SolveBio::Tabulate

    def test_classify

        assert_equal true,  '123.45'.number?
        assert_equal true,  '123'.number?
        assert_equal false, 'spam'.number?
        assert_equal true,  '123'.int?
        assert_equal false, '123.45'.int?

        assert_equal NilClass, _type(nil)
        assert_equal String, _type('foo')
        assert_equal Fixnum, _type('1')
        assert_equal Fixnum, _type(1)
        assert_equal Fixnum, _type('\x1b[31m42\x1b[0m')
    end

    def test_align
        assert_equal( 2, '123.45'.afterpoint)
        assert_equal(-1, '1001'.afterpoint)
        assert_equal(-1, 'eggs'.afterpoint)
        assert_equal( 2, '123e45'.afterpoint)

        assert_equal("  \u044f\u0439\u0446\u0430",
                     "\u044f\u0439\u0446\u0430".padleft(6))
        assert_equal("\u044f\u0439\u0446\u0430  ",
                     "\u044f\u0439\u0446\u0430".padright(6))

        assert_equal(" \u044f\u0439\u0446\u0430 ",
                     "\u044f\u0439\u0446\u0430".padboth(6))

        assert_equal(" \u044f\u0439\u0446\u0430  ",
                     "\u044f\u0439\u0446\u0430".padboth(7))

        assert_equal('abc', 'abc'.padright(2))
        assert_equal('abc', 'abc'.padleft(2))
        assert_equal('abc', 'abc'.padboth(2))


        assert_equal(['   12.345  ', '-1234.5    ', '    1.23   ',
                      ' 1234.5    ', '    1e+234 ', '    1.0e234'],
                     align_column(
                                  ["12.345", "-1234.5", "1.23", "1234.5",
                                   "1e+234", "1.0e234"], "decimal"))
    end

    def test_column_type
        assert_equal(Fixnum, column_type(["1", "2"]))
        assert_equal(Float,  column_type(["1", "2.3"]))
        assert_equal(String, column_type(["1", "2.3", "four"]))
        assert_equal(String,
                     column_type(["four", '\u043f\u044f\u0442\u044c']))
        assert_equal(String, column_type([nil, "brux"]))
        assert_equal(Fixnum, column_type([1, 2, nil]))
    end

    def test_tabulate
        tsv = simple_separated_format("\t")
        assert_equal("foo    1\nspam  23",
                     tabulate([["foo", 1], ["spam", 23]], [], tsv))
    end

end
