#!/usr/bin/env ruby
# Simple use of SolveBio::DatsetField.retrieve

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
if SolveBio.api_key
    fields = SolveBio::DatasetField.retrieve(1)
    puts fields
else
    puts 'Please set SolveBio.api_key. Hint: solvebio.rb login'
end
