#!/usr/bin/env ruby
# Simple use of SolveBio::Query

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio.api_key. Hint: solvebio.rb login'
    exit 1
end

filters = SolveBio::RangeFilter.
    new "hg38", "13", 32200000, 32500000

ds = SolveBio::Dataset.retrieve 'ClinVar/2.0.0-1/Variants'

results = ds.query(:filters => filters)
puts results
