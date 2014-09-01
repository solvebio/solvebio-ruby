#!/usr/bin/env ruby
# Simple use of SolveBio::Depository.retrieve ... facets

require 'solvebio'

# SolveBio::Client.client.api_key = 'set-me-correctly'
if SolveBio::Client.client.api_key
    fields = SolveBio::DatasetField.retrieve(691).facets
    puts fields
else
    puts 'Please set SolveBio::Client.client.api_key. Hint: solvebio.rb login'
end
