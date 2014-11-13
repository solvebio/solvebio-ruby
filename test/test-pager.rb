$VERBOSE = true
require 'test/unit'
require_relative '../lib/pager'

class TestPager < Test::Unit::TestCase

    # When paging is off, results.length should return the number of
    # results retrieved.
    def test_basic
        p = SolveBio::Pager.new(0, 100, 4)
        assert_equal(0, p.first)
        assert_equal(100, p.last)
        assert_equal(4, p.offset_absolute)
        p = SolveBio::Pager.from_range 0..1
        assert_equal(0, p.first)
        assert_equal(true, p.has_next?)
        p.advance
        assert_equal(false, p.has_next?)
    end

end
