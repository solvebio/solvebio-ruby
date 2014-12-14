#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'solvebio'
require 'solvebio/cli'

DIR = File.dirname(__FILE__)

include SolveBio
include SolveBio::CLI
include SolveBio::CLI::Auth
include SolveBio::CLI::Credentials
include SolveBio::CLI::Tutorial

options, argv = process_options(ARGV)
argv = ['shell'] if argv.empty?

cmd = argv.shift
case cmd
when 'shell'
    IRB::shell
when 'login'
    login
when 'logout'
    logout
when 'whoami'
    whoami
when 'tutorial'
    tutorial
else
    $stderr.puts "Unknown subcommand command: #{cmd}"
    $stderr.puts parser
    exit 1
end
