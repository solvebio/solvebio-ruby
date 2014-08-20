#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require_relative '../lib/resource'

class TestResource < Test::Unit::TestCase

    def test_camelcase

        data =
            [
             ['abc',      'abc',        'no camelcase'],
             ['aBcDef',   'a_bc_def',   'letters only'],
             ['abc01Def', 'abc01_def',  'letters and numbers'],
             ['aBcDef',   'a_bc_def',   'multiple letter match'],
             ['a1B2C3',   'a1_b2_c3',   'multi letters and numbers'],
             ['?Foo',     '?_foo',      'weird symbols, part 1'],
            ]
        data.each do |triple|
            assert_equal(triple[1],
                         camelcase_to_underscore(triple[0]),
                         triple[2])
        end
    end

    def test_SolveObject_inspect
        str = SolveBio::SolveObject.new.inspect
        assert(str =~ /^<SolveBio::SolveObject:[[:xdigit:]]+> JSON: {}/,
               'empty SolveObject inspect')
        str = SolveBio::SolveObject.new(62).inspect
        assert(str =~ /^<SolveBio::SolveObject id=62:[[:xdigit:]]+> JSON: {"id":62}/,
               "SolveObject inspect with id #{str}")

    end

    def test_Dataset_from_response
        resp = {
            'class_name' => 'Dataset',
            'data_url'   => 'https://api.solvebio.com/v1/datasets/25/data',
            'depository' => 'ClinVar',
            'depository_id' => 223,
            'depository_version' => 'ClinVar/2.0.0-1',
            'depository_version_id' => 15,
            'description' => '',
            'fields_url' => 'https://api.solvebio.com/v1/datasets/25/fields',
            'full_name' => 'ClinVar/2.0.0-1/Variants',
            'id'  => 25,
            'name' => 'Variants',
            'title' => 'Variants',
            'url' => 'https://api.solvebio.com/v1/datasets/25'
        }
        so = resp.to_biosolve
        assert_equal SolveBio::Dataset, so.class, 'Hash -> SolveObject'
        resp.keys.each {|k| assert_equal resp[k], so[k]}
    end
end
