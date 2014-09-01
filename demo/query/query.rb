#!/usr/bin/env ruby
# Simple use of SolveBio::Query

require 'solvebio'

# SolveBio::Client.client.api_key = 'set-me-correctly'
if SolveBio::Client.client.api_key
    results = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants').query
    puts results
else
    puts 'Please set SolveBio::Client.client.api_key. Hint: solvebio.rb login'
end
