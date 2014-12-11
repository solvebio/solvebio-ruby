module SolveBio
    module Tabulate
        TYPES = {NilClass => 0, Fixnum => 1, Float => 2, String => 4}

        INVISIBILE_CODES = %r{\\x1b\[\d*m}  # ANSI color codes

        Line = Struct.new(:start, :hline, :sep, :last)

        DataRow = Struct.new(:start, :sep, :last)

        TableFormat = Struct.new(:lineabove, :linebelowheader,
                                 :linebetweenrows, :linebelow,
                                 :headerrow, :datarow,
                                 :padding, :usecolons,
                                 :with_header_hide,
                                 :without_header_hide)

        FORMAT_DEFAULTS = {
            :padding             => 0,
            :usecolons           => false,
            :with_header_hide    => [],
            :without_header_hide => []
        }


        INVTYPES = {
            4 => String,
            2 => Float,
            1 => Fixnum,
            0 => NilClass
        }

        SIMPLE_DATAROW = DataRow.new('', '  ', '')
        PIPE_DATAROW   = DataRow.new('|', '|', '|')

        SIMPLE_LINE    = Line.new('', '-', '  ', '')
        GRID_LINE      = Line.new('+', '-', '+', '+')

        TABLE_FORMATS = {
            :simple =>
            TableFormat.new(lineabove           = nil,
                            linebelowheader     = SIMPLE_LINE,
                            linebetweenrows     = nil,
                            linebelow           = SIMPLE_LINE,
                            headerrow           = SIMPLE_DATAROW,
                            datarow             = SIMPLE_DATAROW,
                            padding             = 0,
                            usecolons           = false,
                            with_header_hide    = ['linebelow'],
                            without_header_hide = []),
            :grid =>
            TableFormat.new(lineabove           = SIMPLE_LINE,
                            linebelowheader     = Line.new('+', '=', '+', '+'),
                            linebetweenrows     = SIMPLE_LINE,
                            linebelow           = SIMPLE_LINE,
                            headerrow           = PIPE_DATAROW,
                            datarow             = PIPE_DATAROW,
                            padding             = 1,
                            usecolons           = false,
                            with_header_hide    = [],
                            without_header_hide = ['linebelowheader']),

            :pipe =>
            TableFormat.new(lineabove           = nil,
                            linebelowheader     = Line.new('|', '-', '|', '|'),
                            linebetweenrows     = nil,
                            linebelow           = nil,
                            headerrow           = PIPE_DATAROW,
                            datarow             = PIPE_DATAROW,
                            padding             = 1,
                            usecolons           = true,
                            with_header_hide    = [],
                            without_header_hide = []),

            :orgmode =>
            TableFormat.new(lineabove=nil,
                            linebelowheader     = Line.new('|', '-', '+', '|'),
                            linebetweenrows     = nil,
                            linebelow           = nil,
                            headerrow           = PIPE_DATAROW,
                            datarow             = PIPE_DATAROW,
                            padding             = 1,
                            usecolons           = false,
                            with_header_hide    = [],
                            without_header_hide = ['linebelowheader'])
        }

        module_function

        # Simulate Python's multi-parameter zip function. Ruby's zip
        # function, like Perl's, expects each arg to have dimension 2.
        def python_zip(args)
            result = args.first.reduce([]){|r, i| r << []}
            args.each_with_index do |ary, i|
                ary.each_with_index {|v, j| result[j][i] = v}
            end
            result
        end

        def simple_separated_format(separator)
            # FIXME? python code hard-codes separator = "\n" below.
            return TableFormat
                .new(
                     :lineabove        => nil,
                     :linebelowheader  => nil,
                     :linebetweenrows  => nil,
                     :linebelow        => nil,
                     :headerrow        => nil,
                     :datarow          => DataRow.new('', separator, ''),
                     :padding          => 0,
                     :usecolons        => false,
                     :with_header_hide => [],
                     :without_header_hide => [],
                     )
        end

        # The least generic type, one of NilClass, Fixnum, Float, or String.
        # _type(nil)   => NilClass
        # _type("foo") => String
        # _type("1")   => Fixnum
        # _type("\x1b[31m42\x1b[0m") => Fixnum
        def _type(obj, has_invisible=true)

            obj = obj.strip_invisible if obj.kind_of?(String) and has_invisible

            if obj.nil?
                return NilClass
            elsif obj.kind_of?(Fixnum) or obj.int?
                return Fixnum
            elsif obj.kind_of?(Float) or obj.number?
                return Float
            else
                return String
            end
        end

        # [string] -> [padded_string]
        #
        #    align_column(
        #        ["12.345", "-1234.5", "1.23", "1234.5",
        #         "1e+234", "1.0e234"], "decimal") =>
        #    ['   12.345  ', '-1234.5    ', '    1.23   ',
        #     ' 1234.5    ', '    1e+234 ', '    1.0e234']
        def align_column(strings, alignment, minwidth=0, has_invisible=true)
            if alignment == "right"
                strings = strings.map{|s| s.to_s.strip}
                padfn = :padleft
            elsif alignment == 'center'
                strings = strings.map{|s| s.to_s.strip}
                padfn = :padboth
            elsif alignment == 'decimal'
                decimals = strings.map{|s| s.to_s.afterpoint}
                maxdecimals = decimals.max
                zipped = strings.zip(decimals)
                strings = zipped.map{|s, decs|
                    s.to_s + " " * ((maxdecimals - decs))
                }
                padfn = :padleft
            else
                strings = strings.map{|s| s.to_s.strip}
                padfn = :padright
            end

            if has_invisible
                width_fn = :visible_width
            else
                width_fn = :size
            end

            maxwidth = [strings.map{|s| s.send(width_fn)}.max, minwidth].max
            strings.map{|s| s.send(padfn, maxwidth, has_invisible) }
        end


        def more_generic(type1, type2)
            moregeneric = [TYPES[type1] || 4, TYPES[type2] || 4].max
            return INVTYPES[moregeneric]
        end


        # The least generic type all column values are convertible to.
        #
        #  column_type(["1", "2"]) => Fixnum
        #  column_type(["1", "2.3"]) => Float
        #  column_type(["1", "2.3", "four"]) => String
        #  column_type(["four", '\u043f\u044f\u0442\u044c']) => String
        #  column_type([nil, "brux"]) => String
        #  column_type([1, 2, nil]) => Fixnum
        def column_type(strings, has_invisible=true)
            types = strings.map{|s| _type(s, has_invisible)}
            # require 'trepanning'; debugger
            return types.reduce(Fixnum){
                |t, result|
                more_generic(result, t)
            }
        end


        # Format a value accoding to its type.
        #
        #  Unicode is supported:
        #
        #  >>> hrow = ["\u0431\u0443\u043a\u0432\u0430",
        #              "\u0446\u0438\u0444\u0440\u0430"]
        #      tbl = [["\u0430\u0437", 2], ["\u0431\u0443\u043a\u0438", 4]]
        #      expected = "\\u0431\\u0443\\u043a\\u0432\\u0430      \n
        #                  \\u0446\\u0438\\u0444\\u0440\\u0430\\n-------\n
        #                   -------\\n\\u0430\\u0437             \n
        #                   2\\n\\u0431\\u0443\\u043a\\u0438           4'
        #      tabulate(tbl, hrow) => good_result
        #  true
        def format(val, valtype, floatfmt, missingval="")
            if val.nil?
                return missingval
            end

            if [Fixnum, String, Fixnum].member?(valtype)
                return "%s" % val.to_s
            elsif valtype.kind_of?(Float)
                return "%#{floatfmt}" % Float(val)
            else
                return "%s" % val
            end
        end


        def align_header(header, alignment, width)
            if alignment == "left"
                return header.padright(width)
            elsif alignment == "center"
                return header.padboth(width)
            else
                return header.padleft(width)
            end
        end


        # Transform a supported data type to an Array of Arrays, and an
        # Array of headers.
        #
        #    Supported tabular data types:
        #
        #    * Array-of-Arrays or another Enumerable of Enumerables
        #
        #    * Hash of Enumerables
        #
        #    The first row can be used as headers if headers="firstrow",
        #    column indices can be used as headers if headers="keys".
        #
        def normalize_tabular_data(tabular_data, headers)
            if tabular_data.respond_to?(:keys) and tabular_data.respond_to?(:values)
                # likely a Hash
                keys = tabular_data.keys
                ## FIXME: what's different in the Python code?
                # columns have to be transposed
                # rows = list(izip_longest(*tabular_data.values()))
                # rows = vals[0].zip(*vals[1..-1])
                rows = tabular_data.values
                if headers == "keys"
                    # headers should be strings
                    headers = keys.map{|k| k.to_s}
                end
            elsif tabular_data.kind_of?(Enumerable)
                # Likely an Enumerable of Enumerables
                rows = tabular_data.to_a
                if headers == "keys" and not rows.empty?  # keys are column indices
                    headers = (0..rows[0]).map {|i| i.to_s}
                end
            else
                raise(ValueError, "tabular data doesn't appear to be a Hash" +
                      " or Array")
            end

            # take headers from the first row if necessary
            if headers == "firstrow" and not rows.empty?
                headers = rows[0].map{|row| [_text_type(row)]}
                rows.shift
            end

            # pad with empty headers for initial columns if necessary
            if not headers.empty?  and not rows.empty?
                nhs = headers.size
                ncols = rows[0].size
                if nhs < ncols
                    headers = [''] * (ncols - nhs) + headers
                end
            end

            return rows, headers
        end

        TTY_COLS = ENV['COLUMNS'].to_i || 80 rescue 80
        # Return a string which represents a row of data cells.
        def build_row(cells, padding, first, sep, last)

            pad = ' ' * padding
            padded_cells = cells.map{|cell| pad + cell + pad }
            rendered_cells = (first + padded_cells.join(sep) + last).rstrip

            # Enforce that we don't wrap lines by setting a max
            # limit on row width which is equal to TTY_COLS (see printing)
            if rendered_cells.size > TTY_COLS
                if not cells[-1].end_with?(' ') and not cells[-1].end_with?('-')
                    terminating_str = ' ... '
                else
                    terminating_str = ''
                end
                prefix = rendered_cells[0..TTY_COLS - terminating_str.size - 2]
                rendered_cells = "%s%s%s" % [prefix, terminating_str, last]
            end

            return rendered_cells
        end


        # Return a string which represents a horizontal line.
        def build_line(colwidths, padding, first, fill, sep, last)
            cells = colwidths.map{|w| fill * (w + 2 * padding)}
            return build_row(cells, 0, first, sep, last)
        end


        #  Return a segment of a horizontal line with optional colons which
        #  indicate column's alignment (as in `pipe` output format).
        def _line_segment_with_colons(linefmt, align, colwidth)
            fill = linefmt.hline
            w = colwidth
            if ['right', 'decimal'].member?(align)
                return (fill[0] * (w - 1)) + ":"
            elsif align == "center"
                return ":" + (fill[0] * (w - 2)) + ":"
            elsif align == "left"
                return ":" + (fill[0] * (w - 1))
            else
                return fill[0] * w
            end
        end


        # Produce a plain-text representation of the table.
        def format_table(fmt, headers, rows, colwidths, colaligns)
            lines = []
            hidden = headers ? fmt.with_header_hide : fmt.without_header_hide
            pad = fmt.padding || 0
            datarow = fmt.datarow ? fmt.datarow : SIMPLE_DATAROW
            headerrow = fmt.headerrow ? fmt.headerrow : fmt.datarow

            if fmt.lineabove and hidden and hidden.member?("lineabove")
                lines << build_line(colwidths, pad, *fmt.lineabove)
            end

            unless headers.empty?
                lines << build_row(headers, pad, headerrow.start, headerrow.sep,
                                   headerrow.last)
            end

            if fmt.linebelowheader and not hidden.member?("linebelowheader")
                first, _, sep, last = fmt.linebelowheader
                if fmt.usecolons
                    segs = [
                            colwidths.zip(colaligns).map do |w, a|
                                _line_segment_with_colons(fmt.linebelowheader, a, w + 2 * pad)
                            end ]
                    lines << build_row(segs, 0, first, sep, last)
                else
                    lines << build_line(colwidths, pad, fmt.linebelowheader.start,
                                        fmt.linebelowheader.hline,
                                        fmt.linebelowheader.sep,
                                        fmt.linebelowheader.last)
                end
            end

            if rows and fmt.linebetweenrows and hidden.member?('linebetweenrows')
                # initial rows with a line below
                rows[1..-1].each do |row|
                    lines << build_row(row, pad, fmt.datarow.start,
                                       fmt.datarow.sep, fmt.datarow.last)
                    lines << build_line(colwidths, pad, fmt.linebetweenrows.start,
                                        fmt.linebelowheader.hline,
                                        fmt.linebetweenrows.sep,
                                        fmt.linebetweenrows.last)
                end
                # the last row without a line below
                lines << build_row(rows[-1], pad, datarow.start,
                                    datarow.sep, datarow.last)
            else
                rows.each do |row|
                    lines << build_row(row, pad, datarow.start, datarow.sep,
                                       datarow.last)

                    if fmt.linebelow and hidden.member?('linebelow')
                        lines << build_line(colwidths, pad, fmt.linebelow.start,
                                            fmt.linebelowheader.hline,
                                            fmt.linebelow.sep,
                                            fmt.linebelow.last)
                    end
                end
            end
            return lines.join("\n")
        end

        # Construct a simple TableFormat with columns separated by a separator.
        #
        #   tsv = simple_separated_format("\t")
        #   tabulate([["foo", 1], ["spam", 23]], [], true, tsv) =>
        #     "foo    1\nspam  23"
        def tabulate(tabular_data, headers=[], aligns=[], sort=true,
                     tablefmt=TABLE_FORMATS[:orgmode], floatfmt="g", missingval='')

            tabular_data = tabular_data.sort_by{|x| x[0]} if sort
            list_of_lists, headers = normalize_tabular_data(tabular_data, headers)

            # optimization: look for ANSI control codes once,
            # enable smart width functions only if a control code is found
            plain_rows = [headers.map{|h| h.to_s}.join("\t")]
            row_text = list_of_lists.map{|row|
                row.map{|r| r.to_s}.join("\t")
            }
            plain_rows += row_text
            plain_text = plain_rows.join("\n")

            has_invisible = INVISIBILE_CODES.match(plain_text)
            if has_invisible
                width_fn = :visible_width
            else
                width_fn = :size
            end

            # format rows and columns, convert numeric values to strings
            cols = list_of_lists[0].zip(*list_of_lists[1..-1]) if
                list_of_lists.size > 1

            coltypes = cols.map{|c| column_type(c)}

            cols = cols.zip(coltypes).map do |c, ct|
                c.map{|v| format(v, ct, floatfmt, missingval)}
            end

            # align columns
            if aligns.empty?
                # dynamic alignment by col type
                aligns = coltypes.map do |ct|
                    [Fixnum, Float].member?(ct) ? 'decimal' : 'left'
                end
            end

            minwidths =
                if headers.empty?  then
                    [0] * cols.size
                else
                    headers.map{|h| h.send(width_fn) + 2}
                end

            cols = cols.zip(aligns, minwidths).map do |c, a, minw|
                align_column(c, a, minw, has_invisible)
            end

            if headers.empty?
                minwidths = cols.map{|c| c[0].send(width_fn)}
            else
                # align headers and add headers
                minwidths =
                    minwidths.zip(cols).map{|minw, c| [minw, c[0].send(width_fn)].max}
                headers   =
                    headers.zip(aligns, minwidths).map{|h, a, minw| align_header(h, a, minw)}
            end
            rows = python_zip(cols)

            tablefmt = TABLE_FORMATS[:orgmode] unless
                tablefmt.kind_of?(TableFormat)

            # make sure values don't have newlines or tabs in them
            rows.each do |r|
                r.each_with_index do |c, i|
                    r[i] = c.gsub("\n", '').gsub("\t", '')
                end
            end
            return format_table(tablefmt, headers, rows, minwidths, aligns)
        end
    end

    class Object

        # "123.45".number? => true
        # "123".number?    => true
        # "spam".number?   => false
        def number?
            begin
                Float(self)
                return true
            rescue
                return false
            end
        end

        # "123".int?    => true
        # "123.45".int? => false
        def int?
            begin
                Integer(self)
                return true
            rescue
                return false
            end
        end
    end

    class String

        # Symbols after a decimal point, -1 if the string lacks the decimal point.
        #
        #  "123.45".afterpoint =>  2
        #  "1001".afterpoint   => -1
        #  "eggs".afterpoint   => -1
        #  "123e45".afterpoint =>  2
        def afterpoint
            if self.number?
                if self.int?
                    return -1
                else
                    pos = self.rindex('.') || -1
                    pos = self.downcase().rindex('e') if pos < 0
                    if pos >= 0
                        return self.size - pos - 1
                    else
                        return -1  # no point
                    end
                end
            else
                return -1  # not a number
            end
        end

        def adjusted_size(has_invisible)
            return has_invisible ? self.strip_invisible.size : self.size
        end

        # Visible width of a printed string. ANSI color codes are removed.
        #
        #  ['\x1b[31mhello\x1b[0m' "world"].map{|s| s.visible_width} =>
        #  [5, 5]
        def visible_width
            # if self.kind_of?(_text_type) or self.kind_of?(_binary_type)
                return self.strip_invisible.size
            # else
            #    return _text_type(s).size
            # end
        end


        # Flush right.
        #
        #    '\u044f\u0439\u0446\u0430'.padleft(6) =>
        #    '  \u044f\u0439\u0446\u0430'
        #    'abc'.padleft(2) => 'abc'
        def padleft(width, has_invisible=true)
            s_width = self.adjusted_size(has_invisible)
            s_width < width ? (' ' * (width - s_width)) + self : self
        end

        # Flush left.
        #
        #   padright(6, '\u044f\u0439\u0446\u0430') => '\u044f\u0439\u0446\u0430  '
        #   padright(2, 'abc') => 'abc'
        def padright(width, has_invisible=true)
            s_width = self.adjusted_size(has_invisible)
            s_width < width ? self + (' ' * (width - s_width)) : self
        end


        # Center string with uneven space on the right
        #
        #  '\u044f\u0439\u0446\u0430'.padboth(6) => ' \u044f\u0439\u0446\u0430 '
        #  'abc'.padboth(2) => 'abc'
        #  'abc'.padboth(6) => ' abc  '
        def padboth(width, has_invisible=true)
            s_width = self.adjusted_size(has_invisible)
            return self if s_width >= width
            pad_size   = width - s_width
            pad_left   = ' ' * (pad_size/2)
            pad_right  = ' ' * ((pad_size + 1)/ 2)
            pad_left + self + pad_right
        end

        # Remove invisible ANSI color codes.
        def strip_invisible
            return self.gsub(SolveBio::Tabulate::INVISIBILE_CODES, '')
        end
    end
end
