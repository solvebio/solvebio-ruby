#!/usr/bin/env ruby
# Simple use of SolveBio::DatsetField.retrieve

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio::api_key. Hint: solvebio.rb login'
    exit 1
end

fields = SolveBio::DatasetField.retrieve(1)
puts fields
