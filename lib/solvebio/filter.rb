module SolveBio
    class Filter
        # SolveBio::Filter objects.
        #
        # Makes it easier to create filters cumulatively using ``&`` (and),
        # ``|`` (or) and ``~`` (not) operations.
        #
        # == Example
        #
        #     require 'solvebio'
        #     f =  SolveBio::Filter.new                       #=> <Filter []>
        #     f &= SolveBio::Filter.new :price => 'Free'      #=> <Filter [[:price, "Free"]]>
        #     f |= SolveBio::Filter.new :style => 'Mexican'   #=> <Filter [{:or=>[[:price, "Free"], [:style, "Mexican"]]}]>
        #
        # The final result is a filter that can be used in a query which match es
        # "price = 'Free' or style = 'Mexican'".
        #
        # By default, each key/value pairs are AND'ed together. However, you can change that
        # to OR by passing in +:or+ as the last argument.
        #
        #     * `<field>='value` matches if the field is term filter (exact term)
        #     * `<field>__in=[<item1>, ...]` matches any of the terms <item1> and so on
        #     * `<field>__range=[<start>, <end>]` matches anything from <start> to <end>
        #
        # String terms are not analyzed and are always assumed to be exact matches.
        #
        # Numeric columns can be selected by range using:
        #
        #     * `<field>__gt`: greater than
        #     * `<field>__gte`: greater than or equal to
        #     * `<field>__lt`: less than
        #     * `<field>__lte`: less than or equal to
        #
        # Field action examples:
        #
        #     dataset.query(:gene__in  => ['BRCA', 'GATA3'],
        #                   :chr       => '3',
        #                   :start__gt => 10000,
        #                   :end__lte  => 20000)

        attr_accessor :filters

        # Creates a new Filter, the first argument is expected to be Hash or an Array.
        def initialize(filters={}, conn=:and)
            if filters.kind_of?(Hash)
                @filters = SolveBio::Filter.
                    normalize(filters.keys.sort.map{|key| [key,  filters[key]]})
            elsif filters.kind_of?(Array)
                @filters = filters
            elsif filters.kind_of?(SolveBio::Filter)
                @filters = SolveBio::Filter.deep_copy(filters.filters)
                return self
            else
                raise TypeError, "Invalid filter type #{filters.class}"
            end
            @filters = [{conn => @filters}] if filters.size > 1
            self
        end

        def inspect
            return "<SolveBio::Filter #{@filters.inspect}>"
        end

        def empty?
            @filters.empty?
        end

        # Deep copy
        def clone
            SolveBio::Filter.deep_copy(self)
        end

        # OR and AND will create a new Filter, with the filters from both Filter
        #   objects combined with the connector `conn`.
        # FIXME: should we allow a default conn parameter?
        def combine(other, conn=:and)
            return other.clone if self.empty?

            if other.empty?
                return self.clone
            elsif self.filters[0].member?(conn)
                f = self.clone
                f.filters[0][conn] += other.filters
            elsif other.filters[0].member?(conn)
                f = other.clone
                f.filters[0][conn] += self.filters
            else
                f = initialize(self.clone.filters + other.filters, conn)
            end

            return f
        end

        def |(other)
            return self.combine(other, :or)
        end

        def &(other)
            return self.combine(other, :and)
        end

        def ~()
            f = self.clone

            # not of null filter is null fiter
            return f if f.empty?

            # length of self_filters should never be more than 1
            filters = f.filters.first
            if filters.kind_of?(Hash) and
                filters.member?(:not)
                # The filters are already a single dictionary
                # containing a 'not'. Swap out the 'not'
                f.filters = [filters[:not]]
            else
                # 'not' blocks can contain only dicts or a single tuple filter
                # so we get the first element from the filter list
                f.filters = [{:not => filters}]
            end

            return f
        end

        # Checks and normalizes filter array tuples
        def self.normalize(ary)
            ary.map do |tuple|
                unless tuple.kind_of?(Array)
                    raise(TypeError,
                          "Invalid filter element #{tuple.class}; want Array")
                end
                unless tuple.size == 2
                    raise(TypeError,
                          "Filter element size must be 2; is #{tuple.size}")
                end
                key, value = tuple
                if key.to_s =~ /.+__(.+)$/
                    op = $1
                    unless %w(gt gte lt lte in range contains prefix regexp).member?(op)
                        raise(TypeError,
                              "Invalid field operation #{op} in #{key}")
                    end
                    case op
                    when 'gt', 'gte', 'lt', 'lte'
                        begin
                            value = Float(value)
                        rescue
                            if /\d{4}-\d{2}-\d{2}/ !~ value
                                raise(TypeError,
                                      "Invalid field value #{value} for #{key}; " +
                                      "Should be a number or a date in the format 'YYYY-MM-DD'.")
                            end
                        end
                        tuple = [key, value]
                    when 'range'
                        if value.kind_of?(Range)
                            value = [value.min, value.max]
                        end

                        unless value.kind_of?(Array)
                            raise(TypeError,
                                  "Invalid field value #{value} for #{key}; " +
                                  "Should be an array")
                        end
                        unless value.size == 2
                            raise(TypeError,
                                  "Invalid field value #{value} for #{key}; " +
                                  "Array should have exactly two values")
                        end
                        if value.first > value.last
                            raise(IndexError,
                                  "Invalid field value #{value} for #{key}; " +
                                  "Start value not greater than end value")
                        end
                        
                        begin
                            Float(value.first)
                            Float(value.last)
                        rescue
                            raise(TypeError,
                                  "Invalid field values for #{key}; " +
                                  "Both should be numbers")
                        end

                        tuple = [key, value]
                    when 'in'
                        unless value.kind_of?(Array)
                            raise(TypeError,
                                  "Invalid field value #{value} for #{key}; " +
                                  "Should be an array")
                        end

                    end
                end
                tuple
            end
        end

        def self.deep_copy(obj)
            Marshal.load(Marshal.dump(obj))
        end

        # Takes a SolveBio::Filter or an Array of filter items and returns
        # an Array that can be passed off (when converted to JSON) to a
        # SolveBio client filter parameter. As such, the output format is
        # highly dependent on the SolveBio API format.
        #
        # The filter items can be either a SolveBio::Filter, or Hash of
        # the right form, or an Array of the right form.
        def self.process_filters(filters)
            rv = []
            if filters.kind_of?(SolveBio::Filter)
                if filters.filters
                    rv = process_filters(filters.filters)
                end
            else
                filters.each do |f|
                    if f.kind_of?(SolveBio::Filter)
                        if f.filters
                            rv << process_filters(f.filters)
                            next
                        end
                    elsif f.kind_of?(Hash)
                        key = f.keys[0]
                        val = f[key]

                        if val.kind_of?(Hash)
                            filter_filters = process_filters(val)
                            if filter_filters.size == 1
                                filter_filters = filter_filters[0]
                            end
                            rv << {key => filter_filters}
                        else
                            rv << {key => process_filters(val)}
                        end
                    else
                        rv << f
                    end
                end
            end
            return rv
        end
    end

    class GenomicFilter < Filter
        # Helper class that generates filters on genomic coordinates.
        #
        #    Range filtering only works on "genomic" datasets
        #    (where dataset['is_genomic'] is true).

        # Standardized fields for genomic coordinates in SolveBio
        FIELD_START = 'genomic_coordinates.start'
        FIELD_STOP = 'genomic_coordinates.stop'
        FIELD_CHR = 'genomic_coordinates.chromosome'

        # Handles UCSC-style range queries (chr1:100-200)
        def self.from_string(string, exact=false)
            begin
                chromosome, pos = string.split(':')
            rescue ValueError
                raise ValueError,
                    'Please use UCSC-style format: "chr2:1000-2000"'
            end

            if pos.member?('-')
                start, stop = pos.replace(',', '').split('-')
            else
                start = stop = pos.replace(',', '')
            end

            return self.new(chromosome, start, stop, exact)
        end

        # This class supports single position and range filters.
        #
        # By default, the filter will match any record that overlaps with
        # the position or range specified. Exact matches must be explicitly
        # specified using the `exact` parameter.
        def initialize(chromosome, start, stop=nil, exact=false)
            begin
                if not start.nil?
                    start = Integer(start)
                end

                stop = stop ? Integer(stop) : start
            rescue ValueError
                raise ValueError('Start and stop positions must be integers or nil')
            end

            if exact or start.nil?
                f = SolveBio::Filter.new({FIELD_START => start, FIELD_STOP  => stop})
            else
                f = SolveBio::Filter.new({"#{FIELD_START}__lte" => start,
                                          "#{FIELD_START}__gte" => stop})
                if start != stop
                    f |= SolveBio::Filter.new({"#{FIELD_START}__range" =>
                                               [start, stop + 1]})
                    f |= SolveBio::Filter.new({"#{FIELD_STOP}__range" =>
                                               [start, stop + 1]})
                end
            end

            if chromosome.nil?
                f &= SolveBio::Filter.new({"#{FIELD_CHR}" => nil})
            else
                f &= SolveBio::Filter.new({"#{FIELD_CHR}" => chromosome.sub('chr', '')})
            end

            @filters = f.filters
        end

        def inspect
            return "<GenomicFilter #{@filters}>"
        end
    end
end
