#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'irb'
require 'netrc'
require 'fileutils'
require 'optparse'
require 'readline'
require 'io/console'

require 'solvebio/cli/credentials'
require 'solvebio/cli/auth'
require 'solvebio/cli/irb'
require 'solvebio/cli/tutorial'

module SolveBio
    module CLI
        def process_options(argv)
            options = {}
            opts = setup_options(options)

            begin
                opts.parse!(argv)
            rescue OptionParser::ParseError => error
                $stderr.puts error
                $stderr.puts "(-h or --help will show valid options)"
                exit 1
            end

            SolveBio.api_host = options[:api_host] if options[:api_host]
            SolveBio.api_key = options[:api_key] if options[:api_key]
            
            return options, argv
        end

        # Main parser for the SolveBio command line client
        def setup_options(options, stdout=$stdout, stderr=$stderr)
            OptionParser.new do |opts|
                opts.banner = "Usage: solvebio.rb [options] <command> [<args>]"
                opts.on_tail('-v', '--version',
                             'print the version') do
                    options[:version] = true
                    stdout.puts "solvebio-ruby #{SolveBio::VERSION}"
                    exit 0
                end

                opts.on('--api-host STRING', String,
                        'Override the default SolveBio API host') do
                    |api_host|
                    options[:api_host] = api_host
                end

                opts.on('--api-key STRING', String,
                        'Manually provide a SolveBio API key') do
                    |api_key|
                    options[:api_key] = api_key
                end

                opts.on('-h', '--help', 'Display this screen') do
                    puts opts
                    puts <<-EOH

SolveBio Commands:
    login               Login and save credentials.
    logout              Logout and delete saved credentials.
    whoami              Show your SolveBio email address.
    shell               Open a SolveBio IRB shell.
    tutorial            Start the SolveBio Ruby tutorial.
EOH
                    exit
                end
            end
        end
    end
end
