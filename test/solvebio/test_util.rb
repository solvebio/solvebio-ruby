require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestSolveObject < Test::Unit::TestCase
        # Does our kind of camelCasing works?
        def test_camelcase

            data =
                [
                 ['abc',      'abc',        'no camelcase'],
                 ['aBcDef',   'a_bc_def',   'letters only'],
                 ['abc01Def', 'abc01_def',  'letters and numbers'],
                 ['aBcDef',   'a_bc_def',   'multiple letter match'],
                 ['a1B2C3',   'a1_b2_c3',   'multi letters and numbers'],
                 ['?Foo',     '?_foo',      'weird symbols, part 1'],
                 ['Dataset',  'dataset',    'no camelcase with caps'],
                ]
            data.each do |triple|
                assert_equal(triple[1],
                             Util.camelcase_to_underscore(triple[0]),
                             triple[2])
            end
        end

        def test_pluralize
            data =
                [
                 ['depository',  'depositories', "ends in 'y'"],
                 ['dataset',     'datasets',     "simply adds an 's'"]
                ]
            data.each do |triple|
                assert_equal(triple[1],
                             Util.pluralize(triple[0]),
                             triple[2])
            end

        end
    end
end
