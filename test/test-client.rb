#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'fileutils'
require_relative '../lib/client'

class TestClient < Test::Unit::TestCase

    def test_get
        client = SolveBio::Client.new(nil, 'http://google.com')
        assert client, 'Should be able to create a client'

        # Can we get something from google?
        output = `curl --silent http://www.google.com`
        if $?.success? and output
            assert(client.request('get', 'http://www.google.com',
                                  {:raw => true, :redirect => true}),
                                  'HTTP GET, google.com')
            assert(client.request('get', 'https://www.google.com',
                                  {:raw => true}),
                                  'HTTPS GET google.com')
        else
            skip('Are you connected to the Internet? www.google.com is unavailable')
        end
    end

end
