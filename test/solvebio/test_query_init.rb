require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestQuery < Test::Unit::TestCase
        def test_query_initialize
            [SolveBio::Query].each do |klass|
                assert klass.new(5)
                assert klass.new('clinvar/1.0.0/clinvar')

                assert_raises TypeError do
                    klass.new(:limit => 10)
                end
                
                assert_raises TypeError do
                    klass.new(5.0, :limit => 10.0)
                end

                assert klass.new(5, :limit => 10)
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
end
