#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'fileutils'
require_relative '../lib/cli/credentials'

# Does .netrc reading and manipulation work?
class TestNetrc < Test::Unit::TestCase


    def setup
        @netrc_path_save = ENV["NETRC_PATH"]
        path = ENV['NETRC_PATH'] = File.join(File.dirname(__FILE__), 'data')
        FileUtils.cp(File.join(path, 'netrc-save'), File.join(path, '.netrc'))
        File.chmod(0600, "#{path}/.netrc")
        @old_warn_level = $VERBOSE
        @old_api_host = SolveBio::API_HOST
        $VERBOSE = nil
        SolveBio.const_set(:API_HOST, 'https://api.solvebio.com')
        $VERBOSE = @old_warn_level
    end

    def teardown
        ENV["NETRC_PATH"] = @netrc_path_save
        $VERBOSE = nil
        SolveBio.const_set(:API_HOST, @old_api_host)
        $VERBOSE = @old_warn_level
    end

    include SolveBio::Credentials

    def test_netrc
        assert netrc_path, 'Should get a location for .netrc'
    end

    def test_get_credentials
        assert_equal ['rocky@example.com', 'shhhh'], get_credentials.to_a
    end

    def test_save_credentials
        new_values = get_credentials.map{|x| x+"abc"}
        save_credentials(*new_values)
        assert_equal(new_values, get_credentials.to_a,
                     'Should append "abc" to creds')
    end

    def test_delete_credentials
        delete_credentials
        assert_equal nil, get_credentials, 'Should be able to delete credentials'
    end

end
