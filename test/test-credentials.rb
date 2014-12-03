#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'fileutils'
require_relative '../lib/cli/auth'
require_relative '../lib/cli/credentials'

def silence_output(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
        yield
    ensure
        $stdout = original_stdout
    end
   fake.string
end

# Does reading and manipulation of the SolveBio credentials file work?
class TestNetrc < Test::Unit::TestCase


    def setup
        @home_path_save = ENV['HOME']
        home_path = ENV['HOME'] = File.join(File.dirname(__FILE__), 'data')
        credentials_file = netrc_path
        FileUtils.cp(File.join(home_path, 'netrc-save'), credentials_file)
        File.chmod(0600, credentials_file)
        @old_warn_level = $VERBOSE
        @old_api_host = SolveBio::API_HOST
        $VERBOSE = nil
        SolveBio.const_set(:API_HOST, 'https://api.solvebio.com')
        $VERBOSE = @old_warn_level
    end

    def teardown
        ENV["HOME"] = @home_path_save
        $VERBOSE = nil
        SolveBio.const_set(:API_HOST, @old_api_host)
        $VERBOSE = @old_warn_level
    end

    include SolveBio::Credentials

    def test_netrc
        assert(netrc_path,
               "Should get a location for SolveBio's credentials")
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
        assert_equal(nil, get_credentials,
                     'Should be able to delete credentials')
        pair = ['testagain@solvebio.com', 'b00b00']
        save_credentials(*pair)
        auths = get_credentials()
        assert_equal(pair, auths,
                     "Should get newly set credentials for host #{SolveBio::API_HOST}")

        # Make sure login_if_needed is setting the api key when it finds
        # credentials
        SolveBio.api_key = nil
        silence_output {
            self.assert(SolveBio::Auth::login_if_needed, "Should find credentials")
        }
        self.assert(SolveBio::api_key, "API key should be set when login_if_needed succeeds")
    end

end
