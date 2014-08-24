#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# SolveBio Ruby command-line option processing

require 'optparse'
require_relative '../client'

module SolveBio::CLIOptions

    PROGRAM = 'solvebio.rb'

    # FIXME: remove after we add to help.
    HELP = {
        'login'    => 'Login and save credentials',
        'logout'   => 'Logout and delete saved credentials',
        'whoami'   => 'Show your SolveBio email address',
        'shell'    => 'Open the SolveBio Python shell',
        'test'     => 'Make sure the SolveBio API is working correctly',
    }

    def show_version
        "#{PROGRAM}, version #{SolveBio::VERSION}"
    end

    # Main parser for the SolveBio command line client
    def setup_options(options, stdout=$stdout, stderr=$stderr)

        OptionParser.new do |opts|
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

            # #
            # # The _add_subcommands method must be separate from the __init__
            # #        method, as infinite recursion will occur otherwise, due to the fact
            # #        that the __init__ method itself will be called when instantiating
            # #        a subparser, as we do below
            # def _add_subcommands
            #     subcmd_params = {
            #         'title' => 'SolveBio Commands',
            #         'dest' => 'subcommands'
            #     }
            #     subcmd = self.add_subparsers(*subcmd_params)
            #     login_parser = subcmd.add_parser('login', help=self.HELP['login'])
            #     login_parser.set_defaults(func=auth.login)
            #     logout_parser = subcmd.add_parser('logout', help=self.HELP['logout'])
            #     logout_parser.set_defaults(func=auth.logout)
            #     whoami_parser = subcmd.add_parser('whoami', help=self.HELP['whoami'])
            #     whoami_parser.set_defaults(func=auth.whoami)
            #     shell_parser = subcmd.add_parser('shell', help=self.HELP['shell'])
            #     shell_parser.set_defaults(func=launch_ipython_shell)
            #     shell_parser = subcmd.add_parser('test', help=self.HELP['test'])
            #     shell_parser.set_defaults(func=test_solve_api)
            # end
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
