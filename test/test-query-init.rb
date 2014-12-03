$VERBOSE = true
require 'test/unit'
require_relative '../lib/query'

class TestQuery < Test::Unit::TestCase

    def test_query_initialize
        [SolveBio::Query].each do |klass|
            assert klass.new(5)
            assert klass.new('5')
            assert_raises TypeError do
                # dataset id should be an Fixnum
                klass.new(:limit => 10)
            end
            assert klass.new(5, :limit => 10)
            assert klass.new(5.0, :limit => 10.0)
            assert_raises RangeError do
                # limit should be > 0
                assert klass.new(5, :limit => -1)
            end
            assert_raises TypeError do
                # limit should be a Fixnum
                assert klass.new(5, :limit => 'a')
            end
        end
    end

end
