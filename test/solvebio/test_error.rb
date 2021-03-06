require File.expand_path('../../helper', __FILE__)

$errors = []

class FakeLogger
    def debug(mess)
        $errors << mess
    end
end

module SolveBio
    class TestError < Test::Unit::TestCase
        def test_error
            msg = "hi"
            assert_equal msg, SolveBio::SolveError.new(nil, msg).to_s, "Error.to_s fn"
            response = Net::HTTPUnauthorized.new('HTTP 1.1', '404', 'No creds')
            old_logger = SolveBio.instance_variable_get('@logger')
            logger = FakeLogger.new
            SolveBio.instance_variable_set('@logger', logger)
            old_verbose = $VERBOSE
            $VERBOSE=false
            SolveBio::SolveError.new(response)
            $VERBOSE=old_verbose
            assert_equal ["API Response (404): No content."], $errors
        ensure
            $VERBOSE = old_verbose if old_verbose
            SolveBio.instance_variable_set('@logger', old_logger) if old_logger

        end
    end
end
