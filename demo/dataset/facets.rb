#!/usr/bin/env ruby
# Simple use of SolveBio::DatsetField.retrieve ... facets

require 'solvebio'

# SolveBio.client.api_key = 'set-me-correctly'
if SolveBio.api_key
    fields = SolveBio::DatasetField.retrieve(691).facets
    puts fields
else
    puts 'Please set SolveBio::api_key. Hint: solvebio.rb login'
end
