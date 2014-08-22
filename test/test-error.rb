#!/usr/bin/env ruby
$VERBOSE = true
require 'test/unit'
require 'net/http'
require_relative '../lib/errors'

# require 'trepanning'

$errors = []

class FakeLogger
    def debug(mess)
        $errors << mess
    end
end

class TestError < Test::Unit::TestCase

    def test_error
        msg = "hi"
        assert_equal msg, SolveBio::Error.new(msg).str, "Error.str fn"
        response = Net::HTTPUnauthorized.new('HTTP 1.1', '404', 'No creds')

        old_logger = SolveBio.instance_variable_get('@logger')
        logger = FakeLogger.new
        SolveBio.instance_variable_set('@logger', logger)
        SolveBio::Error.new(nil, response)
        assert_equal ["API Response (404): No content."], $errors
    ensure
        SolveBio.instance_variable_set('@logger', old_logger) if old_logger

    end
end
