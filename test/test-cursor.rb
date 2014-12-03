$VERBOSE = true
require 'test/unit'
require_relative '../lib/cursor'

class TestCursor < Test::Unit::TestCase

    # When paging is off, results.length should return the number of
    # results retrieved.
    def test_basic
        c = SolveBio::Cursor.new(0, 100, 4)
        assert_equal(0, c.first)
        assert_equal(100, c.last)
        assert_equal(4, c.offset_absolute)
        c = SolveBio::Cursor.from_range 0..1
        assert_equal(0, c.first)
        assert_equal(true, c.has_next?)
        c.advance
        assert_equal(false, c.has_next?)
    end

end
