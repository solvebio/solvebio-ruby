require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestResource < Test::Unit::TestCase
        def test_SolveObject_inspect
            str = SolveBio::SolveObject.new.inspect
            assert(str =~ /^#<SolveBio::SolveObject:0x[[:xdigit:]]+>/,
                   'empty SolveObject inspect')
            str = SolveBio::SolveObject.new(62).inspect
            assert(str =~ /^#<SolveBio::SolveObject:0x[[:xdigit:]]+ id=62>/,
                   "SolveObject inspect with id #{str}")

        end

        def test_Dataset_from_response
            resp = {
                :class_name => 'Dataset',
                :depository => 'HGNC',
                :depository_version => 'HGNC/1.0.0-1',
                :full_name => 'HGNC/1.0.0-1/HGNC',
                :name => 'HGNC',
                :title => 'HGNC'
            }
            so = Util.to_solve_object(resp)
            assert_equal SolveBio::Dataset, so.class, 'Hash -> SolveObject'
            resp.keys.each {|k| assert_equal resp[k], so[k]}
        end
    end
end
