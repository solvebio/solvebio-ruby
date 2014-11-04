#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'openssl'
require 'rest_client'
require 'json'
require 'addressable/uri'
require_relative 'credentials'
require_relative 'errors'

# A requests-based HTTP client for SolveBio API resources
class SolveBio::Client

    attr_reader :headers, :api_host
    attr_accessor :api_key

    # Add our own kind of Authorization tokens. This has to be
    # done this way, late, because the rest-client gem looks for
    # .netrc and will set basic authentication if it finds a match.
    RestClient.add_before_execution_proc do | req, args |
        if args[:authorization]
            req.instance_variable_get('@header')['authorization'] = [args[:authorization]]
        end
    end

    def initialize(api_key=nil, api_host=nil)
        @api_key = api_key || SolveBio::api_key
        SolveBio::api_key  ||= api_key
        @api_host = api_host || SolveBio::API_HOST

        # Mirroring comments from:
        # http://ruby-doc.org/stdlib-2.1.2/libdoc/net/http/rdoc/Net/HTTP.html
        # gzip compression is used in preference to deflate
        # compression, which is used in preference to no compression.
        @headers  = {
            :content_type     => :json,
            :accept           => :json,
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'      => 'SolveBio Ruby Client %s [%s/%s]' % [
                SolveBio::VERSION,
                SolveBio::RUBY_IMPLEMENTATION,
                SolveBio::RUBY_VERSION
            ]
        }
    end

    DEFAULT_REQUEST_OPTS = {
        :raw             => false,
        :default_headers => true
    }

    # Issues an HTTP GET across the wire via the Ruby 'rest-client'
    # library. See *request()* for information on opts.
    def get(url, opts={})
        request('get', url, opts)
    end

    # Issues an HTTP POST across the wire via the Ruby 'rest-client'
    # library. See *request* for information on opts.
    def post(url, data, opts={})
        opts[:payload] =
            if opts.member?(:no_json)
                data
            else
                data.to_json
            end
        request('post', url, opts)
    end

    # Issues an HTTP Request across the wire via the Ruby 'rest-client'
    # library.
    def request(method, url, opts={})

        opts = DEFAULT_REQUEST_OPTS.merge(opts)

        # Expand URL with API host if none was given
        api_host = @api_host or SolveBio::API_HOST

        if not api_host
            raise SolveBio::Error.new('No SolveBio API host is set')
        elsif not url.start_with?(api_host)
            url = Addressable::URI.join(api_host, url).to_s
        end

        # Handle some default options and add authorization header
        if opts[:default_headers] and @api_key
            headers = @headers.merge(opts[:headers]||{})
            headers['Authorization'] = "Token #{@api_key}"
            authorization = "Token #{@api_key}"
        else
            headers = nil
            authorization = nil
        end

        SolveBio::logger.debug('API %s Request: %s' % [method.upcase, url])
        # puts 'API %s Request: %s' % [method.upcase, url]
        # puts method, "url: #{url} headers: #{headers}"
        # puts "params: #{opts[:params]}"


        response = nil
        RestClient::Request.
            execute(:method        => method,
                    :url           => url,
                    :headers       => headers,
                    :authorization => authorization,
                    :timeout       => opts[:timeout] || 80,
                    :payload       => opts[:payload]) do
            |resp, request, result, &block|
            response = resp
            if response.code < 200 or response.code >= 400
                self.handle_api_error(result)
            end
        end

        response = JSON.parse(response) unless opts[:raw]
        response
    end

    def self.handle_request_error(e)
        # FIXME: go over this. It is still a rough translation
        # from the python.
        err = e.inspect
        if e.kind_of?(requests.exceptions.RequestException)
            msg = SolveBio::Error::Default_message
        else
            msg = "Unexpected error communicating with SolveBio.\n" +
                "It looks like there's probably a configuration " +
                'issue locally.\nIf this problem persists, let us ' +
                'know at contact@solvebio.com.'
        end
        msg = msg + "\n\n(Network error: #{err}"
        raise SolveBio::Error.new(nil, msg)
    end

    # SolveBio's API error handler returns a SolveBio::Error.  The
    # *response* parameter is a (subclass) of Net::HTTPResponse.
    def handle_api_error(response)
        SolveBio::logger.info("API Error: #{response.msg}") unless
            [400, 401, 403, 404].member?(response.code.to_i)
        raise SolveBio::Error.new(response)
    end

    def self.client
        @@client ||= SolveBio::Client.new()
    end

    def self.get(*args)
        client.get(*args)
    end

    def self.post(*args)
        client.post(*args)
    end

    def self.request(*args)
        client.request(*args)
    end

end
