# -*- coding: utf-8 -*-
#
# This file contains code from python-tabulate, modified for SolveBio
#
# Copyright © 2011-2013 Sergey Astanin
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# from __future__ require 'print_function'
# from __future__ require 'unicode_literals'

# from collections require 'namedtuple'
# from platform require 'python_version_tuple'

# if python_version_tuple()[0] < "3"
#     from itertools require 'izip_longest'
#     _none_type = type(nil)
#     _int_type = int
#     _float_type = float
#     _text_type = unicode
#     _binary_type = str
# else
#     from itertools require 'zip_longest as izip_longest'
#     from functools require 'reduce'
#     _none_type = type(nil)
#     _int_type = int
#     _float_type = float
#     _text_type = str
#     _binary_type = bytes
# end


require_relative 'main'
module SolveBio::Tabulate

    VERSION = '0.6'

    TYPES = {:none_type => 0, :int => 1, :float => 2, :text_type => 4}

    # Line = namedtuple("Line", ["begin", "hline", "sep", "end"])
    # DataRow = namedtuple("DataRow", ["begin", "sep", "end"])
    # TableFormat = namedtuple("TableFormat", ["lineabove", "linebelowheader",
    #                                          "linebetweenrows", "linebelow",
    #                                          "headerrow", "datarow",
    #                                          "padding", "usecolons",
    #                                          "with_header_hide",
    #                                          "without_header_hide"])
    # _format_defaults = {"padding"  => 0,
    #     "usecolons"  => false,
    #     "with_header_hide"  => [],
    #     "without_header_hide"  => []}


    # _table_formats = {
    #     "simple" =>
    #     TableFormat(lineabove=nil,
    #                 linebelowheader=Line("", "-", "  ", ""),
    #                 linebetweenrows=nil,
    #                 linebelow=Line("", "-", "  ", ""),
    #                 headerrow=DataRow("", "  ", ""),
    #                 datarow=DataRow("", "  ", ""),
    #                 padding=0,
    #                 usecolons=false,
    #                 with_header_hide=["linebelow"],
    #                 without_header_hide=[]),
    #     "plain" =>
    #     TableFormat(nil, nil, nil, nil,
    #                 DataRow("", "  ", ""), DataRow("", "  ", ""),
    #                 **_format_defaults),

    #     "grid" =>
    #     TableFormat(lineabove=Line("+", "-", "+", "+"),
    #                 linebelowheader=Line("+", "=", "+", "+"),
    #                 linebetweenrows=Line("+", "-", "+", "+"),
    #                 linebelow=Line("+", "-", "+", "+"),
    #                 headerrow=DataRow("|", "|", "|"),
    #                 datarow=DataRow("|", "|", "|"),
    #                 padding=1,
    #                 usecolons=false,
    #                 with_header_hide=[],
    #                 without_header_hide=["linebelowheader"]),

    #     "pipe" =>
    #     TableFormat(lineabove=nil,
    #                 linebelowheader=Line("|", "-", "|", "|"),
    #                 linebetweenrows=nil,
    #                 linebelow=nil,
    #                 headerrow=DataRow("|", "|", "|"),
    #                 datarow=DataRow("|", "|", "|"),
    #                 padding=1,
    #                 usecolons=true,
    #                 with_header_hide=[],
    #                 without_header_hide=[]),

    #     "orgmode" =>
    #     TableFormat(lineabove=nil,
    #                 linebelowheader=Line("|", "-", "+", "|"),
    #                 linebetweenrows=nil,
    #                 linebelow=nil,
    #                 headerrow=DataRow("|", "|", "|"),
    #                 datarow=DataRow("|", "|", "|"),
    #                 padding=1,
    #                 usecolons=false,
    #                 with_header_hide=[],
    #                 without_header_hide=["linebelowheader"])
    # }

    INVISIBILE_CODES = %r{\\x1b\[\d*m}  # ANSI color codes

    # Construct a simple TableFormat with columns separated by a separator.
    #
    #   >>> tsv = simple_separated_format("\t") ; \
    #        tabulate([["foo", 1], ["spam", 23]], \
    #            tablefmt=tsv) == 'foo \\t 1\\nspam\\t23'
    #   true
    def simple_separated_format(separator)
        return TableFormat(nil, nil, nil, nil,
                           headerrow=nil, datarow=DataRow('', '\t', ''),
                           _format_defaults={})
    end


    # number?("123.45") => true
    # number?("123") => true
    # number?("spam") => false
    def number?(string)
        begin
            Float(string)
            return true
        rescue
            return false
        end
    end

    # int?("123") => true
    # int?("123.45") => false
    def int?(string)
        begin
            Integer(string)
            return true
        rescue
            return false
        end
    end

    # The least generic type (type(nil), int, float, str, unicode).
    # _type(nil) => type(nil)
    # _type("foo") => TYPE[:text_type]
    # _type("1") => TYPE[:int]
    # _type('\x1b[31m42\x1b[0m') => TYPE[:int]
    def _type(str, has_invisible=true)

        str = strip_invisible(str) if str.kind_of?(String)  and has_invisible

        if str.nil?
            return TYPES[:none_type]
        elsif int?(str)
            return TYPES[:int]
        elsif number?(str)
            return TYPES[:float]
        else
            return TYPES[:text_type]
        end
    end


    #
    # Symbols after a decimal point, -1 if the string lacks the decimal point.
    #
    #  >>> _afterpoint("123.45")
    #  2
    #  >>> _afterpoint("1001")
    #  -1
    #  >>> _afterpoint("eggs")
    #  -1
    #  >>> _afterpoint("123e45")
    #  2
    def _afterpoint(string)
        if number?(string)
            if _isint(string)
                return -1
            else
                pos = string.rfind(".")
                pos = string.downcase().rfind('e') if pos < 0
                if pos >= 0
                    return string.size - pos - 1
                else
                    return -1  # no point
                end
            end
        else
            return -1  # not a number
        end
    end

    # Flush right.
    #
    #    >>> _padleft(6, u'\u044f\u0439\u0446\u0430') \
    #    == u'  \u044f\u0439\u0446\u0430'
    #    true
    def _padleft(width, s, has_invisible=true)
        width += s.size - strip_invisible(s).size if has_invisible
        (' ' * width) + s
    end

    # Flush left.
    #
    # >>> _padright(6, u'\u044f\u0439\u0446\u0430') \
    #    == u'\u044f\u0439\u0446\u0430  '
    #    true
    def _padright(width, s, has_invisible=true)
        width += s.size - strip_invisible(s).size if has_invisible
        return fmt.format(s)
        s + (' ' * width)
    end


    # Center string.
    #
    #  >>> _padboth(6, u'\u044f\u0439\u0446\u0430') \
    #       == u' \u044f\u0439\u0446\u0430 '
    #   true
    def _padboth(width, s, has_invisible=true)
        width += width + s.size - strip_invisible(s).size if
            has_invisible
        pad = ' ' * iwidth
        pad + s + pad
    end


    # Remove invisible ANSI color codes.
    def strip_invisible(s)
        return s.gsub(INVISIBILE_CODES, '')
    end


    # Visible width of a printed string. ANSI color codes are removed.
    #
    #  >>> _visible_width('\x1b[31mhello\x1b[0m'), _visible_width("world")
    #  (5, 5)
    def _visible_width(s)
        if s.kind_of?(_text_type) or s.kind_of?(_binary_type)
            return strip_invisible(s).size
        else
            return _text_type(s).size
        end
    end


    # [string] -> [padded_string]
    #
    #    >>> list(map(str,_align_column( \
    #        ["12.345", "-1234.5", "1.23", "1234.5", \
    #         "1e+234", "1.0e234"], "decimal")))
    #    ['   12.345  ', '-1234.5    ', '    1.23   ', \
    #     ' 1234.5    ', '    1e+234 ', '    1.0e234']
    def _align_column(strings, alignment, minwidth=0, has_invisible=true)
        if alignment == "right"
            strings = strings.map{|s| s.strip}
            padfn = :_padleft
        elsif alignment.member?['center']
            strings = strings.map{|s| s.strip}
            padfn = :_padboth
        elsif alignment.member?['decimal']
            decimals = strings.map{|s| _afterpoint(s)}
            maxdecimals = max(decimals)
            zipped = strings.zip(decimals)
            strings = zipped.map{|s| s + (maxdecimals - decs) * " "}
            padfn = :_padleft
        else
            strings = strings.map{|s| s.strip}
            padfn = :_padright
        end

        if has_invisible
            width_fn = :_visible_width
        else
            width_fn = :size
        end

        maxwidth = [strings.map{|s| s.call(width_fn)}.max, minwidth].max
        strings.map{|s| padfn.call(maxwidth, s, has_invisible) }
    end


    def _more_generic(type1, type2)
        invtypes = {4 => '_text_type', 2 => 'float', 1 => 'int', 0 => :none_type}
        moregeneric = [types[type1] || 4, types[type2] || 4].max
        return invtypes[moregeneric]
    end


    # The least generic type all column values are convertible to.
    #
    #  >>> _column_type(["1", "2"]) is _int_type
    #  true
    #  >>> _column_type(["1", "2.3"]) is _float_type
    #  true
    #  >>> _column_type(["1", "2.3", "four"]) is _text_type
    #  true
    #  >>> _column_type(["four", u'\u043f\u044f\u0442\u044c']) is _text_type
    #  true
    #  >>> _column_type([nil, "brux"]) is _text_type
    #  true
    #  >>> _column_type([1, 2, nil]) is _int_type
    #  true
    def _column_type(strings, has_invisible=true)
        types = strings.map{|s| _type(s, has_invisible)}
        return reduce(_more_generic, types, int)
    end


    # Format a value accoding to its type.
    #
    #  Unicode is supported:
    #
    #  >>> hrow = [u'\u0431\u0443\u043a\u0432\u0430', \
    #                u'\u0446\u0438\u0444\u0440\u0430'] ; \
    #        tbl = [[u'\u0430\u0437', 2], [u'\u0431\u0443\u043a\u0438', 4]] ; \
    #       good_result = u'\\u0431\\u0443\\u043a\\u0432\\u0430      \
    #                       \\u0446\\u0438\\u0444\\u0440\\u0430\\n-------\
    #                          -------\\n\\u0430\\u0437             \
    #                          2\\n\\u0431\\u0443\\u043a\\u0438           4' ; \
    #        tabulate(tbl, headers=hrow) == good_result
    #  true
    def _format(val, valtype, floatfmt, missingval="")
        if val.nil?
            return missingval
        end

        if [Fixnum, _binary_type.class, _text_type.class].member?(valtype)
            return "%s" % val
        elsif valtype.kind_of?(Float)
            return "%#{floatfmt}" % Float(val)
        else
            return "%s" % val
        end
    end


    def _align_header(header, alignment, width)
        if alignment == "left"
            return _padright(width, header)
        elsif alignment == "center"
            return _padboth(width, header)
        else
            return _padleft(width, header)
        end
    end


    # Transform a supported data type to a list of lists, and a list of headers.
    #
    #    Supported tabular data types:
    #
    #    * list-of-lists or another iterable of iterables
    #
    #    * 2D NumPy arrays
    #
    #    * dict of iterables (usually used with headers="keys")
    #
    #    * pandas.DataFrame (usually used with headers="keys")
    #
    #    The first row can be used as headers if headers="firstrow",
    #    column indices can be used as headers if headers="keys".
    #
    def _normalize_tabular_data(tabular_data, headers)
        if tabular_data.respond_to?("keys") and tabular_data.respond_to?("values")
            # dict-like and pandas.DataFrame?
            if hasattr(tabular_data.values, "__call__")
                # likely a conventional dict
                keys = tabular_data.keys()
                # columns have to be transposed
                rows = list(izip_longest(*tabular_data.values()))
            elsif hasattr(tabular_data, "index")
                # values is a property, has .index then
                # it's likely a pandas.DataFrame (pandas 0.11.0)
                keys = tabular_data.keys()
                # values matrix doesn't need to be transposed
                vals = tabular_data.values
                names = tabular_data.index
                zipped = names.zip(vals)
                rows = zipped.map{|v, row| [v] + [row]}
            else
                raise(ValueError, "tabular data doesn't appear to be a dict " +
                      "or a DataFrame")
            end

            if headers == "keys"
                headers = keys.map{|k| _text_type(k)}  # headers should be strings
            end

        else  # it's a usual an iterable of iterables, or a NumPy array
            rows = tabular_data.to_a

            if headers == "keys" and rows.size > 0  # keys are column indices
                headers = (0..rows[0]).map {|i| _text_type(i)}
            end
        end

        # take headers from the first row if necessary
        if headers == "firstrow" and rows.size > 0
            headers = rows[0].map{|row| [_text_type(row)]}
            rows.shift
        end

        headers = list(headers)

        rows = rows.map{|row| [row]}

        # pad with empty headers for initial columns if necessary
        if headers and rows.size > 0
            nhs = headers.size
            ncols = rows[0].size
            if nhs < ncols
                headers = [''] * (ncols - nhs) + headers
            end
        end

        return rows, headers
    end

    TTY_COLS = ENV['COLUMNS'] || 80
    # Return a string which represents a row of data cells.
    def _build_row(cells, padding, first, sep, last)

        pad = ' ' * padding
        padded_cells = cells.map{|cell| pad + cell + pad }

        # SolveBio: we're only displaying Key-Value tuples (dimension of 2).
        #  enforce that we don't wrap lines by setting a max
        #  limit on row width which is equal to TTY_COLS (see printing)
        rendered_cells = (first + padded_cells.join.sep + last).rstrip
        if rendered_cells.size > TTY_COLS
            if not cells[-1].end_with?(' ') and not cells[-1].end_with?('-')
                terminating_str = ' ... '
            else
                terminating_str = ''
            end
            prefix = rendered_cells[1..TTY_COLS - terminating_str.size - 1]
            rendered_cells = "%s%s%s" % [prefix, terminating_str, last]
        end

        return rendered_cells
    end


    # Return a string which represents a horizontal line.
    def _build_line(colwidths, padding, first, fill, sep, last)
        cells = colwidths.map{|w| fill * (w + 2 * padding)}
        return _build_row(cells, 0, first, sep, last)
    end


    # Prefix every cell in a row with an HTML alignment attribute.
    def _mediawiki_cell_attrs(row, colaligns)
        alignment = {"left"  => '',
            "right"  => 'align="right"| ',
            "center"  => 'align="center"| ',
            "decimal"  => 'align="right"| '}
        zipped = row.zip(colaligns)
        row2 = zipped.map{|c, a| alignment[a] + c }
        return row2
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
    def _format_table(fmt, headers, rows, colwidths, colaligns)
        lines = []
        hidden = headers ? fmt.with_header_hide : fmt.without_header_hide
        pad = fmt.padding
        headerrow = fmt.headerrow ? fmt.headerrow : fmt.datarow

        if fmt.lineabove and hidden.member?("lineabove")
            lines << _build_line(colwidths, pad, *fmt.lineabove)
        end

        lines << _build_row(headers, pad, *headerrow) if headers

        if fmt.linebelowheader and not hidden.member?("linebelowheader")
            first, fill, sep, last = fmt.linebelowheader
            if fmt.usecolons
                segs = [
                        colwidths.zip(colaligns).map do |w, a|
                            _line_segment_with_colons(fmt.linebelowheader, a, w + 2 * pad)
                        end ]
                lines << _build_row(segs, 0, first, sep, last)
            else
                lines << _build_line(colwidths, pad, *fmt.linebelowheader)
            end
        end

        if rows and fmt.linebetweenrows and hidden.member?('linebetweenrows')
            # initial rows with a line below
            rows[1..-1].each do |row|
                lines << _build_row(row, pad, *fmt.datarow)
                lines << _build_line(colwidths, pad, *fmt.linebetweenrows)
            end
            # the last row without a line below
            lines << _build_row(rows[-1], pad, *fmt.datarow)
        else
            rows.each do |row|
                lines << _build_row(row, pad, *fmt.datarow)

                if fmt.linebelow and hidden.member?('linebelow')
                    lines << _build_line(colwidths, pad, *fmt.linebelow)
                end
            end
        end
        return lines.join("\n")
    end

    # def tabulate(tabular_data, headers=[], tablefmt="orgmode",
    #              floatfmt="g", aligns=[], missingval='')
    #     list_of_lists, headers = _normalize_tabular_data(tabular_data, headers)

    #     # # optimization: look for ANSI control codes once,
    #     # # enable smart width functions only if a control code is found
    #     # plain_text = "\n".join(
    #     #     ["\t".join(map(_text_type, headers))]
    #     #     + ["\t".join(map(_text_type, row)) for row in list_of_lists])

    #     has_invisible = re.search(INVISIBILE_CODES, plain_text)
    #     if has_invisible
    #         width_fn = :_visible_width
    #     else
    #         width_fn = :size
    #     end

    #     # format rows and columns, convert numeric values to strings
    #     cols = list(zip(*list_of_lists))

    #     coltypes = list(map(_column_type, cols))
    #     # cols = [[_format(v, ct, floatfmt, missingval) for v in c]
    #     #         for c, ct in zip(cols, coltypes)]


    #     # align columns
    #     unless aligns
    #         # dynamic alignment by col type
    #         aligns = coltypes.map do |ct|
    #             [Fixnum, Float].member?(ct) ? 'decimal' : 'left'
    #         end
    #     end

    #     minwidths =
    #         if headers then
    #             headers.map{|h| width_fn.call(h) + 2}
    #         else
    #             [0] * cols.size
    #         end
    #     # cols = [_align_column(c, a, minw, has_invisible)
    #     #     for c, a, minw in zip(cols, aligns, minwidths)]

    #     if headers
    #         # align headers and add headers
    #         minwidths = [max(minw, width_fn(c[0]))
    #                      for minw, c in zip(minwidths, cols)]
    #                      headers = zip(headers, aligns, minwidths).map do |h, a|
    #             _align_header(h, a, minw)
    #         end
    #                      rows = cols[0].zip(cols[1])
    #                  else
    #                      minwidths = cols.map{|c| width_fn.call(c[0])}
    #                      rows = cols[0].zip(cols[1])
    #                  end

    #         unless tablefmt.kind_of?(TableFormat):
    #                 tablefmt = _table_formats.get(tablefmt, _table_formats["orgmode"])
    #         end

    #         # make sure values don't have newlines or tabs in them
    #         rows = row.map{|r| r[0], r[1].replace("\n", '').replace("\t", '')}
    #         return _format_table(tablefmt, headers, rows, minwidths, aligns)
    #     end
end

if __FILE__ == $0
    include SolveBio::Tabulate
    puts 'num? 123.45 %s' % number?("123.45") # true
    puts "num? 123: %s" % number?("123")      # true
    puts "num? spam: %s" % number?("spam")    # false
    puts 'int? 123 %s' % int?("123")          # true
    puts 'int? 123.45 %s' % int?('124.45')    # false

    puts "_type(nil) %s = %s" % [_type(nil), TYPES[:none_type]]
    puts "_type('foo') %s = %s" % [_type('foo'), TYPES[:text_type]]
    puts "_type('1') %s = %s" % [_type('1'), TYPES[:int]]
    puts "_type(''\x1b[31m42\x1b[0m') %s = %s" % [_type('\x1b[31m42\x1b[0m'), TYPES[:int]]

end
