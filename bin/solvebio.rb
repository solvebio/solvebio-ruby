#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# SolveBio Ruby command-line program

require_relative '../lib/solvebio'
require_relative '../lib/cli/options'
require_relative '../lib/cli/irb'

DIR = File.dirname(__FILE__)
TEST_PROGRAM = File.join(DIR, %w(.. demo test-api.rb))

include SolveBio::CLIOptions
options, rest, parser = process_options(ARGV)

rest = ['shell'] if rest.empty?

include SolveBio::Auth

rest.each do |cmd|
    case cmd
    when 'shell'
        IRB::shell
    when 'login'
        login
    when 'logout'
        logout
    when 'whoami'
        whoami
    when 'test'
        system(TEST_PROGRAM)
    else
        $stderr.puts "Unknown solvbio.rb command: #{cmd}"
        $stderr.puts parser
        exit 1
    end
end
