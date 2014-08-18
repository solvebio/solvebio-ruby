#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'fileutils'
require_relative '../lib/client'

# require 'trepanning'

class TestClient < Test::Unit::TestCase

    def test_get
        client = SolveBio::Client.new(nil, 'http://google.com')
        assert client, 'Should be able to create a client'

        # Can we get something from google?
        output = `curl --silent http://www.google.com`
        if $?.success? and output
            assert(client.request('http', 'http://www.google.com', nil,
                                  true), 'HTTP GET, google.com')
            assert(client.request('https', 'https://www.google.com', nil,
                                  true), 'HTTPS GET google.com')
        end
    end

end
