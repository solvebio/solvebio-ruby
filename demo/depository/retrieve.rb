#!/usr/bin/env ruby
# Simple use of SolveBio::Depository.retrieve

require 'solvebio'

# SolveBio::Client.client.api_key = 'set-me-correctly'
if SolveBio.api_key
    depo = SolveBio::Depository.retrieve('ClinVar')
    puts depo.to_s
else
    puts 'Please set SolveBio.api_key. Hint: solvebio.rb login'
end
