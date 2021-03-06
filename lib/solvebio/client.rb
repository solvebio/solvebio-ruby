module SolveBio
    class Client
        attr_reader :headers
        attr_accessor :api_host, :token

        # Add our own kind of Authorization tokens. This has to be
        # done this way, late, because the rest-client gem looks for
        # .netrc and will set basic authentication if it finds a match.
        RestClient.add_before_execution_proc do | req, args |
            if args[:authorization]
                req.instance_variable_get('@header')['authorization'] = [args[:authorization]]
            end
        end

        def initialize(api_host=nil, token=nil, token_type='Token')
            @token = token
            @token_type = token_type
            @api_host = api_host

            # Mirroring comments from:
            # http://ruby-doc.org/stdlib-2.1.2/libdoc/net/http/rdoc/Net/HTTP.html
            # gzip compression is used in preference to deflate
            # compression, which is used in preference to no compression.
            @headers  = {
                :content_type     => :json,
                :accept           => :json,
                'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'      => 'SolveBio Ruby Client %s' % [
                    SolveBio::VERSION,
                ]
            }
        end

        DEFAULT_REQUEST_OPTS = {
            :raw             => false,
            :default_headers => true,
            :auth            => true,
            :json            => true
        }

        # Issues an HTTP GET across the wire via the Ruby 'rest-client'
        # library. See *request()* for information on opts.
        def get(url, opts={})
            request('get', url, opts)
        end

        # Issues an HTTP POST across the wire via the Ruby 'rest-client'
        # library. See *request* for information on opts.
        def post(url, data, opts={})
            opts[:payload] = data
            request('post', url, opts)
        end
        
        def put(url, data, opts={})
            opts[:payload] = data
            request('put', url, opts)
        end

        # Issues an HTTP Request across the wire via the Ruby 'rest-client'
        # library.
        def request(method, url, opts={})
            opts = DEFAULT_REQUEST_OPTS.merge(opts)

            # Expand URL with API host if none was given
            api_host = @api_host || SolveBio.api_host

            if not api_host
                raise SolveError.new('No SolveBio API host is set')
            elsif not url.start_with?(api_host)
                url = Addressable::URI.join(api_host, url).to_s
            end

            # Handle some default options and add authorization header
            headers = opts[:default_headers] ? @headers.merge(opts[:headers] || {}) : nil

            if opts[:auth]
                if token.nil?
                    if SolveBio.access_token
                        token = SolveBio.access_token
                        token_type = 'Bearer'
                    elsif SolveBio.api_key
                        token = SolveBio.api_key
                        token_type = 'Token'
                    end
                end
                authorization = token ? "#{token_type} #{token}" : nil
            end

            # In Rest-Client, GET params are parsed from headers[:params]
            if opts[:params]
                headers.merge!({:params => opts[:params]})
            end

            # By default, encode payload as JSON
            if ['post', 'put', 'patch'].include?(method.downcase) and opts[:json]
                opts[:payload] = opts[:payload].to_json
            end

            SolveBio::logger.debug('API %s Request: %s' % [method.upcase, url])

            response = nil
            begin
                RestClient::Request.
                    execute(:method        => method,
                            :url           => url,
                            :headers       => headers,
                            :authorization => authorization,
                            :timeout       => opts[:timeout] || 80,
                            :payload       => opts[:payload]) do
                    |resp, request, result, &block|
                    response = resp
                    if 429 == response.code
                        delay = Integer(response.headers[:retry_after])
                        SolveBio::logger.warn("Too many requests, sleeping for #{delay}s.")
                        sleep(delay)
                        return request(method, url, opts)
                    elsif response.code < 200 or response.code >= 400
                        handle_api_error(response)
                    end
                end
            rescue RestClient::Exception => e
                handle_request_error(e)
            end

            if opts[:raw]
                return response
            end

            begin
                response = JSON.parse(response)
            rescue JSON::ParserError => e
                handle_request_error(e)
            end

            Util.symbolize_names(response)
        end

        def handle_request_error(e)
            err = e.inspect
            SolveBio::logger.error("API Error: #{err}")
            msg = "Unexpected error communicating with SolveBio.\n" +
                  "If this problem persists, let us " +
                  "know at contact@solvebio.com."
            raise SolveError.new(nil, msg)
        end

        def handle_api_error(response)
            SolveBio::logger.error("API Error: #{response}") unless
                [400, 401, 403, 404].member?(response.code.to_i)
            raise SolveError.new(response)
        end

        def self.client
            @@client ||= SolveBio::Client.new()
        end

        def self.get(url, opts={})
            client.get(url, opts)
        end

        def self.post(url, data, opts={})
            client.post(url, data, opts)
        end
        
        def self.put(url, data, opts={})
            client.put(url, data, opts)
        end

        def self.request(method, url, opts={})
            client.request(method, url, opts)
        end
    end
end
