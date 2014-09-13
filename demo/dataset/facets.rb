#!/usr/bin/env ruby
# Simple use of SolveBio::DatsetField.retrieve ... facets

require 'solvebio'

# SolveBio.client.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio::api_key. Hint: solvebio.rb login'
    exit 1
end

fields = SolveBio::DatasetField.retrieve(691).facets
puts fields
