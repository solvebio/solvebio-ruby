# -*- coding: utf-8 -*-

require_relative 'main'

# SolveBio::Filter objects.
#
# Makes it easier to create filters cumulatively using ``&`` (and),
# ``|`` (or) and ``~`` (not) operations.
#
# For example::
#
#     f =  SolveBio::Filter.new
#     f &= SolveBio::Filter.new :price => 'Free'
#     f |= SolveBio::Filter.new :style => 'Mexican'
#
# creates a filter "price = 'Free' or style = 'Mexican'".
#
# Each set of kwargs in a `Filter` are ANDed together:
#
#     * `<field>=''` uses a term filter (exact term)
#     * `<field>__in=[]` uses a terms filter (match any)
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
#     dataset.query(gene__in=['BRCA', 'GATA3'],
#                   chr='3',
#                   start__gt=10000,
#                   end__lte=20000)

class SolveBio::Filter

    attr_accessor :filters

    # Creates a new Filter, the first argument is expected to be Hash or an Array.
    #
    def initialize(filters={}, conn=:and)
        if filters.kind_of?(Hash)
            @filters = filters.keys.sort.map{|key| [key,  filters[key]]}
        elsif filters.kind_of?(Array)
            @filters = filters
        else
            raise RuntimeError, "Invalid filter type #{filters.class}"
        end
        @filters = [{conn => @filters}] if filters.size > 1
        self
    end

    def inspect
        return "<Filter #{@filters.inspect}>"
    end

    def empty?
        @filters.empty?
    end

    # Deep copy
    def clone
        Marshal.load(Marshal.dump(self))
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
            f.filters[0][conn] << other.filters
        elsif other.filters[0].member?(conn)
            f = other.clone
            f.filters[0][conn] << self.filters
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


    # Takes an Array of filter items and returns an Array that can be
    # passed off (when converted to JSON) to a SolveBio client filter
    # parameter. As such, the output format is highly dependent on
    # the SolveBio API format.
    #
    # The filter items can be either a SolveBio::Filter, or Hash of
    # the right form, or an Array of the right form.
    def self.process_filters(filters)
        rv = []
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
            elsif f.kind_of?(Array)
                rv << f
            else
                raise TypeError, "Invalid filter class #{f.class}"
            end
        end
        return rv
    end


end

#
#    Helper class that generates Range Filters from UCSC-style ranges.
#
class SolveBio::RangeFilter < SolveBio::Filter
    SUPPORTED_BUILDS = ['hg18', 'hg19', 'hg38']

    #    Handles UCSC-style range queries (hg19:chr1:100-200)
    def self.from_string(string, overlap=false)
        begin
            build, chromosome, pos = string.split(':')
        rescue ValueError
            raise ValueError,
                'Please use UCSC-style format: "hg19:chr2:1000-2000"'
        end

        if pos.member?('-')
            start, last = pos.replace(',', '').split('-')
        else
            start = last = pos.replace(',', '')
        end

        return self.new(build, chromosome, start, last, overlap=overlap)
    end

    #  Shortcut to do range queries on supported datasets.
    def initialize(build, chromosome, start, last, overlap=false)
        if SUPPORTED_BUILDS.member?(build.downcase)
            msg = "Build #{build} not supported for range filters. " +
                "Supported builds are: #{SUPPORTED_BUILDS.join(', ')}"
            raise Exception, msg
        end

        f = self.new({"#{[start, last]}_start__range" => [start, last]})

        if overlap
            f |= self.new({"#{[start, last]}_start__range" => [start, last]})
        else
            f = f & self.new({"#{build}_start__range" => [start, last]})
        end

        f = f & self.new({"#{build}_chromosome" =>
                             chromosome.str.replace('chr', '')})
        @filters = f.filters
    end

    def inspect
        return "<RangeFilter #{@filters}>"
    end
end


# Demo/test code
if __FILE__ == $0
    puts SolveBio::Filter.process_filters([[:omim_id, nil]]).inspect
    f = SolveBio::Filter.new
    puts "%s, empty?: %s" % [f.inspect, f.empty?]
    f_not = ~f
    puts "%s, empty?: %s" % [f_not.inspect, f_not.empty?]
    f2 = SolveBio::Filter.new({:style => 'Mexican', :price => 'Free'})
    puts "%s, empty? %s" % [f2.inspect, f2.empty?]
    f2_not = ~f2
    puts "%s, empty? %s" % [f2_not.inspect, f2_not.empty?]
    # FIXME: using a hash means we can't repeat chr1. Is this intended?
    f2_or = SolveBio::Filter.new({:chr1 => '3', :chr2 => '4'}, :or)
    puts "%s, empty %s" % [f2_or.inspect, f2_or.empty?]
    f2_or = SolveBio::Filter.new({:chr1 => '3'}) | SolveBio::Filter.new({:chr2 => '4'})
    puts "%s, empty %s" % [f2_or.inspect, f2_or.empty?]
    puts((f2_or & f2).inspect)
end
