#!/usr/bin/env ruby
# Simple use of SolveBio::Query with simple equality tests, sometimes
# with "and" or "or"

# require 'solvebio'
require_relative  '../../lib/solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio::api_key. Hint: solvebio.rb login'
    exit 1
end

ds = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')

results = ds.query.filter :hg19_start => 148562304

results = ds.query.filter :hg19_start__in  => [148562304, 148459988]
puts results
