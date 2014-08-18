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
end
