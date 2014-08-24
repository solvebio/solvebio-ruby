#!/usr/bin/env ruby
# Simple use of SolveBio::Depository.retrieve

require 'solvebio'

# SolveBio::Client.client.api_key = 'set-me-correctly'
if SolveBio::Client.client.api_key
    depo = SolveBio::Depository.retrieve('ClinVar')
    puts depo.str
else
    puts 'Please set SolveBio::Client.client.api_key. Hint: solvebio.rb login'
end
