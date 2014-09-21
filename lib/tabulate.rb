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

    TYPES = {NilClass => 0, Fixnum => 1, Float => 2, String => 4}

    # Line = namedtuple("Line", ["begin", "hline", "sep", "end"])

    DataRow = Struct.new(:begin, :send, :sep)
    # DataRow = namedtuple("DataRow", ["begin", "sep", "end"])

    # TableFormat = namedtuple("TableFormat", ["lineabove", "linebelowheader",
    #                                          "linebetweenrows", "linebelow",
    #                                          "headerrow", "datarow",
    #                                          "padding", "usecolons",
    #                                          "with_header_hide",
    #                                          "without_header_hide"])

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

    # _table_formats = {
    #     "simple" =>
    #     TableFormat.new(lineabove=nil,
    #                     linebelowheader=Line("", "-", "  ", ""),
    #                     linebetweenrows=nil,
    #                     linebelow=Line("", "-", "  ", ""),
    #                     headerrow=DataRow.new("", "  ", ""),
    #                     datarow=DataRow.new("", "  ", ""),
    #                     padding=0,
    #                     usecolons=false,
    #                     with_header_hide=["linebelow"],
    #                     without_header_hide=[]),
    #     "plain" =>
    #     TableFormat.new(nil, nil, nil, nil,
    #                     DataRow.new("", "  ", ""), DataRow.new("", "  ", ""),
    #                     :format_defaults => FORMAT_DEFAULTS),

    #     "grid" =>
    #     TableFormat.new(lineabove=Line("+", "-", "+", "+"),
    #                     linebelowheader=Line("+", "=", "+", "+"),
    #                     linebetweenrows=Line("+", "-", "+", "+"),
    #                     linebelow=Line("+", "-", "+", "+"),
    #                     headerrow=DataRow.new("|", "|", "|"),
    #                     datarow=DataRow.new("|", "|", "|"),
    #                     padding=1,
    #                     usecolons=false,
    #                     with_header_hide=[],
    #                     without_header_hide=["linebelowheader"]),

    #     "pipe" =>
    #     TableFormat.new(lineabove=nil,
    #                     linebelowheader=Line("|", "-", "|", "|"),
    #                     linebetweenrows=nil,
    #                     linebelow=nil,
    #                     headerrow=DataRow.new("|", "|", "|"),
    #                     datarow=DataRow.new("|", "|", "|"),
    #                     padding=1,
    #                     usecolons=true,
    #                     with_header_hide=[],
    #                     without_header_hide=[]),

    #     "orgmode" =>
    #         TableFormat.new(lineabove=nil,
    #                     linebelowheader=Line("|", "-", "+", "|"),
    #                     linebetweenrows=nil,
    #                     linebelow=nil,
    #                     headerrow=DataRow.new("|", "|", "|"),
    #                     datarow=DataRow.new("|", "|", "|"),
    #                     padding=1,
    #                     usecolons=false,
    #                     with_header_hide=[],
    #                     without_header_hide=["linebelowheader"])
    # }

    # Construct a simple TableFormat with columns separated by a separator.
    #
    #   >>> tsv = simple_separated_format("\t") ; \
    #        tabulate([["foo", 1], ["spam", 23]], \
    #            tablefmt=tsv) == 'foo \\t 1\\nspam\\t23'
    #   true
    def simple_separated_format(separator)
        return TableFormat
            .new(
                 :headerrow => nil,
                 :datarow => DataRow.new('', '\t', ''),
                 :format_defaults => {})
    end


    # The least generic type, one of NilClass, Fixnum, Float, or String.
    # _type(nil)   => NilClass
    # _type("foo") => String
    # _type("1")   => Fixnum
    # _type('\x1b[31m42\x1b[0m') => Fixnum
    def _type(str, has_invisible=true)

        str = str.strip_invisible if str.kind_of?(String) and has_invisible

        if str.nil?
            return NilClass
        elsif str.kind_of?(Fixnum) or str.int?
            return Fixnum
        elsif str.kind_of?(Float) or str.number?
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
            strings = strings.map{|s| s.strip}
            padfn = :padleft
        elsif alignment == 'center'
            strings = strings.map{|s| s.strip}
            padfn = :padboth
        elsif alignment == 'decimal'
            decimals = strings.map{|s| s.afterpoint}
            maxdecimals = decimals.max
            zipped = strings.zip(decimals)
            strings = zipped.map{|s, decs|
                s.to_s + " " * ((maxdecimals - decs))
            }
            padfn = :padleft
        else
            strings = strings.map{|s| s.strip}
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
    #  >>> hrow = ['\u0431\u0443\u043a\u0432\u0430', \
    #                '\u0446\u0438\u0444\u0440\u0430'] ; \
    #        tbl = [['\u0430\u0437', 2], ['\u0431\u0443\u043a\u0438', 4]] ; \
    #       good_result = '\\u0431\\u0443\\u043a\\u0432\\u0430      \
    #                       \\u0446\\u0438\\u0444\\u0440\\u0430\\n-------\
    #                          -------\\n\\u0430\\u0437             \
    #                          2\\n\\u0431\\u0443\\u043a\\u0438           4' ; \
    #        tabulate(tbl, headers=hrow) == good_result
    #  true
    def format(val, valtype, floatfmt, missingval="")
        if val.nil?
            return missingval
        end

        if [Fixnum, String, Fixnum].member?(valtype)
            return "%s" % val
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
            if tabular_data.respond_to?(:keys)
                # likely a conventional Hash
                keys = tabular_data.keys()
                # columns have to be transposed
                rows = list(izip_longest(*tabular_data.values()))
            elsif tabular_data.respond_to?(:index)
                # values is a property, has .index then
                # it's likely a pandas.DataFrame (pandas 0.11.0)
                keys = tabular_data.keys()
                # values matrix doesn't need to be transposed
                vals = tabular_data.values
                names = tabular_data.index
                zipped = names.zip(vals)
                rows = zipped.map{|v, row| [v] + [row]}
            else
                raise(ValueError, "tabular data doesn't appear to be a Hash " +
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
            first, _, sep, last = fmt.linebelowheader
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
    #         width_fn = :visible_width
    #     else
    #         width_fn = :size
    #     end

    #     # format rows and columns, convert numeric values to strings
    #     cols = list(zip(*list_of_lists))

    #     coltypes = list(map(column_type, cols))
    #     # cols = [[format(v, ct, floatfmt, missingval) for v in c]
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
    #     # cols = [align_column(c, a, minw, has_invisible)
    #     #     for c, a, minw in zip(cols, aligns, minwidths)]

    #     if headers
    #         # align headers and add headers
    #         minwidths = [max(minw, width_fn(c[0]))
    #                      for minw, c in zip(minwidths, cols)]
    #                      headers = zip(headers, aligns, minwidths).map do |h, a|
    #             align_header(h, a, minw)
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

class String

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


    INVISIBILE_CODES = %r{\\x1b\[\d*m}  # ANSI color codes

    # Remove invisible ANSI color codes.
    def strip_invisible
        return self.gsub(INVISIBILE_CODES, '')
    end

end

if __FILE__ == $0
    include SolveBio::Tabulate
    # puts '" 123.45".num? %s'    % "123.45".number?() # true
    # puts "'123'.num?: %s"       % '123'.number?      # true
    # puts "'spam'.num? spam: %s" % "spam".number?     # false
    # puts "'123'.int? %s"        %  "123".int?        # true
    # puts "'123.45'int?: %s"     % '124.45'.int?      # false

    puts "_type(nil) %s = %s" % [_type(nil), NilClass]
    puts "_type('foo') %s = %s" % [_type('foo'), String]
    puts "_type('1') %s = %s" % [_type('1'), Fixnum]
    puts "_type(''\x1b[31m42\x1b[0m') %s = %s" % [_type('\x1b[31m42\x1b[0m'), Fixnum]

    # puts "'123.45'.afterpoint:   2 == %d" % '123.45'.afterpoint
    # puts "'1001'afterpoint   :  -1 == %d" % '1001'.afterpoint
    # puts "'eggs'.afterpoint  :  -1 == %d" % 'eggs'.afterpoint
    # puts "'123e45'.afterpoint:   2 == %d" % "123e45".afterpoint

    # puts("'\u044f\u0439\u0446\u0430'.padleft(6) = '%s' == '%s'" %
    #      ["\u044f\u0439\u0446\u0430".padleft(6),
    #      "  \u044f\u0439\u0446\u0430"])
    # puts("'abc'.padleft(2) = '%s' == '%s'" %
    #      ['abc'.padleft(2), 'abc'])
    # puts("padright(2, 'abc') = '%s' == '%s'" %
    #      ['abc'.padright(2), 'abc'])
    # puts("'abc'.padboth(2) = '%s' == '%s'" %
    #      ['abc'.padboth(2), 'abc'])
    # puts("'abc'.padboth(6) = '%s' == '%s'" %
    #      ['abc'.padboth(6), ' abc  '])

    # puts align_column(
    #                   ["12.345", "-1234.5", "1.23", "1234.5",
    #                    "1e+234", "1.0e234"], "decimal")

    # puts '=' * 30
    # puts ['   12.345  ', '-1234.5    ', '    1.23   ',
    #      ' 1234.5    ', '    1e+234 ', '    1.0e234']

    puts('column_type(["1", "2"]) is Fixnum == %s ' %
         column_type(["1", "2"]))
    puts('column_type(["1", "2.3"]) is Float == %s ' %
         column_type(["1", "2.3"]))
    puts('column_type(["1", "2.3", "four"]) is String => %s ' %
         column_type(["1", "2.3", "four"]))
    puts('column_type(["four", "\u043f\u044f\u0442\u044c"]) is text => %s ' %
         column_type(["four", "\u043f\u044f\u0442\u044c"]))
    puts('column_type([nil, "brux"]) is String => %s ' %
         column_type([nil, "brux"]))
    puts('column_type([1, 2, nil]) is Fixnum => %s ' %
         column_type([1, 2, nil]))
end
