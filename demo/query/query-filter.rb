#!/usr/bin/env ruby
# Simple use of SolveBio::Query with simple equality tests, sometimes
# with "and" or "or"

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio::api_key. Hint: solvebio.rb login'
    exit 1
end

ds = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')

results = ds.query.filter :hg19_start__in  => [148562304, 148459988]

puts results.to_h  # Show as a hash
puts '=' * 10
puts results       # show in a more formatted way

# Here is the same thing but a little more inefficiently

filters2 =
    SolveBio::Filter.new(:hg19_start => 148459988) |
    SolveBio::Filter.new(:hg19_start => 148562304) |

results = ds.query(:filters => filters2)

puts '=' * 10
puts results
