require File.expand_path('../../helper', __FILE__)

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

module SolveBio
    class TestNetrc < Test::Unit::TestCase
        include SolveBio::CLI::Credentials
        include SolveBio::CLI::Auth

        def setup
            @home_path_save = ENV['HOME']
            home_path = ENV['HOME'] = File.join(File.dirname(__FILE__), 'data')
            credentials_file = netrc_path
            FileUtils.cp(File.join(home_path, 'netrc-save'), credentials_file)
            File.chmod(0600, credentials_file)
            @old_warn_level = $VERBOSE
            @old_api_host = SolveBio.api_host
            $VERBOSE = nil
            SolveBio.api_host = 'https://api.solvebio.com'
            $VERBOSE = @old_warn_level
        end

        def teardown
            ENV["HOME"] = @home_path_save
            $VERBOSE = nil
            SolveBio.api_host = @old_api_host 
            $VERBOSE = @old_warn_level
        end

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
                         "Should get newly set credentials for host #{SolveBio.api_host}")
        end

    end
end
