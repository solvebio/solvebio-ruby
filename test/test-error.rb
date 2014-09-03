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
        assert_equal msg, SolveBio::Error.new(nil, msg).to_s, "Error.to_s fn"
        response = Net::HTTPUnauthorized.new('HTTP 1.1', '404', 'No creds')
        old_logger = SolveBio.instance_variable_get('@logger')
        logger = FakeLogger.new
        SolveBio.instance_variable_set('@logger', logger)
        old_verbose = $VERBOSE
        $VERBOSE=false
        SolveBio::Error.new(response)
        $VERBOSE=old_verbose
        assert_equal ["API Response (404): No content."], $errors
    ensure
        $VERBOSE = old_verbose if old_verbose
        SolveBio.instance_variable_set('@logger', old_logger) if old_logger

    end
end
