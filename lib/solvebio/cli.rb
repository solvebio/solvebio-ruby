#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'irb'
require 'netrc'
require 'fileutils'
require 'optparse'
require 'readline'
require 'io/console'

require 'solvebio/cli/auth'
require 'solvebio/cli/credentials'
require 'solvebio/cli/irb'
require 'solvebio/cli/tutorial'

module SolveBio
    module CLI
        PROGRAM = 'solvebio.rb'

        def show_version
            "#{PROGRAM}, version #{SolveBio::VERSION}"
        end

        def process_options(argv)
            options = {}
            args  = setup_options(options)
            rest  = args.parse argv

            SolveBio::Client.client.api_host =  options[:api_host] if
                options[:api_host]
            SolveBio::Client.client.api_key =  options[:api_key] if
                options[:api_key]
            return options, rest, args
        end

        # Main parser for the SolveBio command line client
        def setup_options(options, stdout=$stdout, stderr=$stderr)

            OptionParser.new do |opts|
                opts.banner = "Usage: solvebio.rb [options] <command> [<args>]"
                opts.on_tail('-v', '--version',
                             'print the version') do
                    options[:version] = true
                    stdout.puts "#{PROGRAM}, version #{SolveBio::VERSION}"
                    exit 0
                end

                opts.on('--api-host NAME', String,
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
