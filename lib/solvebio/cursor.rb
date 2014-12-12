module SolveBio
    class Cursor
        # 2**62 - 1 fits Rubywise into a 64-bit Fixnum
        INT_MAX ||= 4_611_686_018_427_387_903

        attr_reader   :first
        attr_accessor :last   # we can update last, when last == -1
        attr_accessor :offset
        attr_accessor :limit

        def offset_absolute
            return @first + @offset
        end

        def self.from_range(range, offset=0)
            new(range.first, range.last, offset)
        end

        def initialize(first, last, offset=0, limit=INT_MAX)
            reset(first, last, offset, limit)
        end

        def advance(incr=1)
            @offset += incr
        end

        # reset parameters:
        #  - `first`: Absolute first position
        #  - `last`: Absolute last position
        #  - `offset` (optional): Cursor offset relative to `first`
        #  - `limit` (optional): Maximum absolute stop position
        def reset(first, last, offset=0, limit=INT_MAX)
            @first = first
            @last = last
            @offset = offset
            @limit = limit
        end

        #
        # Reset the internal offset from an absolute position.
        #
        #  :Parameters:
        # - `offset_absolute`: Absolute cursor offset
        #
        def reset_absolute(absolute_offset)
            @offset = absolute_offset - @first
        end

        def has_next?
            @offset >= 0 and @offset < (@last - @first)
        end
        
        def can_advance?
            offset_absolute < @limit
        end

        def to_s
            "range: #{@first}..#{@last}: offset #{@offset}"
        end
    end
end
