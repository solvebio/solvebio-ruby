#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'solvebio/cli/main'

DIR = File.dirname(__FILE__)

include SolveBio::CLI
include SolveBio::CLI::Auth
include SolveBio::CLI::Tutorial

options, args, parser = process_options(ARGV)
args = ['shell'] if args.empty?

cmd = args.shift
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
