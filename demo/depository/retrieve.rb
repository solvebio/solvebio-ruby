#!/usr/bin/env ruby
# Simple use of SolveBio::Depository.retrieve

require 'solvebio'

# SolveBio.api_key = 'set-me-correctly'
unless SolveBio.api_key
    puts 'Please set SolveBio.api_key. Hint: solvebio.rb login'
    exit 1
end

depo = SolveBio::Depository.retrieve('ClinVar')
puts depo.to_s
