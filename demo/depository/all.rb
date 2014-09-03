#!/usr/bin/env ruby
# Simple use of SolveBio::Depository.all

require 'solvebio'

# SolveBio::Client.client.api_key = 'set-me-correctly'
if SolveBio.api_key
    depo = SolveBio::Depository.all
    puts depo.to_s
else
    puts 'Please set SolveBio::Client.client.api_key. Hint: solvebio.rb login'
end
