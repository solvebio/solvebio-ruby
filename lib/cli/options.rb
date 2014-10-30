#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# SolveBio Ruby command-line option processing

require 'optparse'
require_relative '../client'

module SolveBio::CLIOptions

    PROGRAM = 'solvebio.rb'

    def show_version
        "#{PROGRAM}, version #{SolveBio::VERSION}"
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
    login [email]       Login and save credentials. Use email if provided.
    logout              Logout and delete saved credentials
    whoami              Show your SolveBio email address
    shell               Open a SolveBio IRB shell
    test                Make sure the SolveBio API is working correctly
EOH
                exit
            end
        end
    end

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

if __FILE__ == $0
    include SolveBio::CLIOptions
    options, rest, parser  = process_options(ARGV)
    p options, rest, parser
end
