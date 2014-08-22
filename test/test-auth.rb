#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'rbconfig'

# require 'trepanning'

class TestAuth < Test::Unit::TestCase

    # Integration test of logout
    def test_logout

        auth_prog = File.join(File.dirname(__FILE__),
                              '..', 'lib', 'cli', 'auth.rb')
        ruby=RbConfig.ruby
        # Dunno if we are logged in or out - log out
        output = `#{ruby} #{auth_prog} logout`
        assert $?, "Should be able to run Ruby on #{auth_prog}"
        # We should be logged out. Try again, and check message.
        output = `#{ruby} #{auth_prog} logout`.chomp
        assert_equal 'You are not logged-in.', output
        # We should be logged out. Try to get status
        output = `#{ruby} #{auth_prog} whoami`.chomp
        assert_equal 'You are not logged-in.', output
    end
end
