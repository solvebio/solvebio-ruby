#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'rbconfig'
require_relative '../lib/credentials'

class TestAuth < Test::Unit::TestCase

    include SolveBio::Credentials

    def run_it(cmd)
        output = `#{cmd}`
        assert_equal 0, $?.to_i, "Should be able to run #{cmd}"
        output.chomp
    end

    def setup
        ruby=RbConfig.ruby
        @auth_prog = File.join(File.dirname(__FILE__),
                               '..', 'lib', 'cli', 'auth.rb')
        @logout_cmd = "#{ruby} #{@auth_prog} logout"
        @@whoami_cmd = "#{ruby} #{@auth_prog} whoami"

        # Save who I was so we can compare at the end
        @i_was = run_it @@whoami_cmd

        begin
            @@creds = get_credentials
        rescue CredentialsError
            @@creds = nil
        end
    end

    def teardown
        # Restore creds to what they were when we started
        save_credentials(*@@creds) if @@creds
        i_am = run_it @@whoami_cmd
        assert_equal(@i_was, i_am,
                     'get_credential and save_creditentials be idempotent')
    end

    # Integration test of logout
    def test_logout
        skip :test_logout, "Can't test logout on weird environments" if
            SolveBio::API_HOST != 'https://api.solvebio.com'

        # Dunno if we are logged in or out - log out
        output = run_it @logout_cmd
        # We should be logged out. Try again, and check message.
        output = run_it @logout_cmd
        assert_equal 'You are not logged-in.', output
        # We should be logged out. Try to get status
        output = run_it @@whoami_cmd
        assert_equal 'You are not logged-in.', output
    end

end
