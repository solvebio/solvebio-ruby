module SolveBio
    class Cursor
        # Cursors are used by the Query class to keep track of pagination.
        #
        # A Cursor tracks a Query's result buffer, specifically what slice
        # of the whole result-set is contained with the buffer.
        #
        # The Cursor contains a buffer of objects (filled by Query.execute).
        # When iterating through a Query result-set, the Cursor tracks the
        # offset through the buffer and notifies the Query when a new page
        # must be retrieved.
        #
        # The Cursor properties are:
        attr_accessor :buffer           # contains a list of results from a query result page.
        attr_accessor :buffer_offset    # The current offset within the buffer array, used when iterating.
        attr_accessor :query_offset     # The absolute offset of the buffer within the full query result-set.

        def initialize
            reset
        end

        def reset(query_offset=0)
            @buffer = nil
            @buffer_offset = nil
            @query_offset = query_offset
        end
        
        def set_buffer(buffer)
            # Set a new buffer and reset the buffer_offset.
            @buffer = buffer
            @buffer_offset = 0
        end

        def has_range?(start, stop)
            # Returns true if the buffer contains the records from start->stop (relative to entire result-set)
            return @buffer && start >= @query_offset && stop < (@query_offset + @buffer.length)
        end

        def has_key?(key)
            return @buffer && key >= @query_offset && key < (@query_offset + @buffer.length)
        end

        def next
            # Return the current item in the buffer
            # and increment buffer_offset.
            if @buffer_offset < @buffer.length
                @buffer_offset += 1
                return @buffer[@buffer_offset-1]
            end
        end

        def has_next?
            if @buffer.nil?
                return false
            else
                return @buffer_offset < @buffer.length
            end
        end

        def first
            # Returns the first value in the buffer
            return @buffer[0]
        end

        def to_s
            "Cursor #{@buffer_offset}/#{@buffer.length}/#{@query_offset}"
        end
    end
end
