#
#    Stateful cursor object that tracks of the range and offset of a Query.
#
require_relative 'main'
class SolveBio::Pager

    attr_reader   :first
    attr_accessor :last   # we can update last, when last == -1
    attr_accessor :offset

    def offset_absolute
        return @first + @offset
    end

    def self.from_range(range, offset=0)
        new(range.first, range.last, offset)
    end

    def initialize(first, last, offset=0)
        reset(first, last, offset)
    end

    def advance(incr=1)
        @offset += incr
    end

    # reset parameters:
    #  - `first`: Absolute first position
    #  - `last`: Absolute last position
    #  - `offset` (optional): Pager offset relative to `first`
    def reset(first, last, offset=0)
        @first = first
        @last = last
        @offset = offset
    end

    #
    # Reset the internal offset from an absolute position.
    #
    #  :Parameters:
    # - `offset_absolute`: Absolute pager offset
    #
    def reset_absolute(absolute_offset)
        @offset = absolute_offset - @first
    end

    def has_next?
        @offset >= 0 and @offset < (@last - @first)
    end

    def to_s
        "range: #{@first}..#{@last}: offset #{@offset}"
    end
end

# Demo/test code
if __FILE__ == $0
    p = SolveBio::Pager.new(0, 100, 4)
    p = SolveBio::Pager.from_range 0..3
    puts p.advance, p.has_next?
    puts p.advance, p.has_next?
    puts p.advance, p.has_next?
    puts p.reset(0, 1)
    puts p.has_next?
    puts p.advance, p.has_next?
end
