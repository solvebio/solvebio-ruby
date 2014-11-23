#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
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
        old_verbose = $VERBOSE
        $VERBOSE=nil
        SolveBio::Tabulate.const_set(:TTY_COLS, 80)
        $VERBOSE=old_verbose
        tsv = simple_separated_format("\t")
        expected = <<-EOS
foo    1
spam  23
EOS
        assert_equal(expected.chomp, tabulate([["foo", 1], ["spam", 23]], [], [],
                                              false, tsv),
                     'simple separated format table')
        ####################################################################
        expected = <<-EOS
| буква   |   цифра |
|---------+---------|
| аз      |       2 |
| буки    |       4 |
EOS
        hrow = ["\u0431\u0443\u043a\u0432\u0430", "\u0446\u0438\u0444\u0440\u0430"]
        tbl = [["\u0430\u0437", 2], ["\u0431\u0443\u043a\u0438", 4]]
        assert_equal(expected.chomp, SolveBio::Tabulate.tabulate(tbl, hrow),
                     'org mode with header and unicode')

        ###################################################################
        expected = <<-EOS
|                Fields | Data                        |
|-----------------------+-----------------------------|
|     alternate_alleles | T                           |
|       clinical_origin | somatic                     |
| clinical_significance | other                       |
|          gene_symbols | CPB1                        |
|       hg18_chromosome | 3                           |
|       hg19_chromosome | 3                           |
|            hg19_start | 148562304                   |
|            hg38_start | 148844517                   |
|                  hgvs | NC_000003.12:g.148844517C>T |
|          rcvaccession | RCV000060731                |
|  rcvaccession_version | 2                           |
|      reference_allele | C                           |
|                  rsid | rs150241322                 |
|                  type | SNV                         |
EOS

        hash = {
            "alternate_alleles"    => ["T"],
            "clinical_origin"      => ["somatic"],
            "clinical_significance"=> "other",
            "gene_symbols"         => ["CPB1"],
            "hg18_chromosome"      => "3",
            "hg19_chromosome"      => "3",
            "hg19_start"           => 148562304,
            "hg38_start"           => 148844517,
            "hgvs"                 => ["NC_000003.12:g.148844517C>T"],
            "rcvaccession"         => "RCV000060731",
            "rcvaccession_version" => 2,
            "reference_allele"     => "C",
            "rsid"                 => "rs150241322",
            "type"                 => "SNV"
        }
        assert_equal(expected.chomp, tabulate(hash.to_a,
                                              ['Fields', 'Data'],
                                              ['right', 'left']),
                     'mixed data with arrays; close to actual query output')
    end

end
