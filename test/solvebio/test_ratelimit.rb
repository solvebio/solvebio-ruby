require File.expand_path('../../helper', __FILE__)

module SolveBio
    class ClientRateLimit < Test::Unit::TestCase
        def setup
            WebMock.enable!
        end

        def teardown
            WebMock.disable!
        end

        def test_rate_limit

            responses = [
                {:body => '{"id": 5}', :status => 429,
                 :headers => {:retry_after => 1}},
                {:body => '{"id": 5}', :status => 200},
            ]
            depo = SolveBio::Depository.new('HGNC')
            stub_request(:get, SolveBio::api_host + depo.url).
                to_return(responses).then.to_raise(Exception)
            start_time = Time.now()
            SolveBio::Depository.retrieve('HGNC')
            elapsed_time = Time.now() - start_time
            assert(elapsed_time > 1.0,
                                   "Should have delayed for over a second; " +
                                   "(was %s)" % elapsed_time)
        end
    end
end
