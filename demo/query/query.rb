#!/usr/bin/env ruby
# Simple use of SolveBio::Query

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio.api_key. Hint: solvebio.rb login'
    exit 1
end

dataset = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')
puts dataset.query
