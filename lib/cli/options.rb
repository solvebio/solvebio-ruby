#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# SolveBio Ruby command-line option processing

require 'optparse'
require_relative '../client'

module SolveBio::CLIOptions

    PROGRAM = 'solvebio.rb'

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

# Try to parse the args first, and then add the subparsers. We want
# to do this so that we can check to see if there are any unknown
# args. We can assume that if, by this point, there are no unknown
# args, we can append shell to the unknown args as a default.
# However, to do this, we have to suppress stdout/stderr during the
# initial parsing, in case the user calls the help method (in which
# case we want to add the additional arguments and *then* call the
# help method. This is a hack to get around the fact that argparse
# doesn't allow default subcommands.
def parse_args(args=nil, namespace=nil)
    begin
        sys.stdout = sys.stderr = open(os.devnull, 'w')
        _, unknown_args = self.parse_known_args(args, namespace)
        args.insert(0, 'shell') unless unknown_args
    rescue SystemExit
        pass
    ensure
        sys.stdout.flush()
        sys.stderr.flush()
        sys.stdout, sys.stderr = sys.__stdout__, sys.__stderr__
    end
    _add_subcommands()
    return super(SolveArgumentParser, self).parse_args(args, namespace)
end

def process_options(argv)
    options = {}
    args  = setup_options(options)
    rest  = args.parse argv

    SolveBio::Client.client.api_host =  options[:api_host] if
        options[:api_host]
    SolveBio::Client.client.api_key =  options[:api_key] if
        options[:api_key]
    return options, rest
end

if __FILE__ == $0
    include SolveBio::CLIOptions
    options, rest = process_options(ARGV)
    p options, rest
end
