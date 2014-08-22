#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'uri'
require 'net/http'
require 'json'
require_relative 'solvebio'
require_relative 'credentials'
require_relative 'errors'

# import textwrap

# A requests-based HTTP client for SolveBio API resources
class SolveBio::Client

    attr_reader :headers, :api_host
    attr_accessor :api_key

    def initialize(api_key=nil, api_host=nil)
        @api_key = api_key
        @api_host = api_host || SolveBio::API_HOST
        @headers = {
            'Content-Type'    => 'application/json',
            'Accept'          => 'application/json',
            'Accept-Encoding' => 'gzip,deflate',
            'User-Agent'      => 'SolveBio Ruby Client %s [%s/%s]' % [
                SolveBio::VERSION,
                SolveBio::RUBY_IMPLEMENTATION,
                SolveBio::RUBY_VERSION
            ]
        }
    end

    def request(method, url, params=nil, raw=false)

        if not @api_host
            raise SolveBio::Error.new('No SolveBio API host is set')
        elsif not url.start_with?(@api_host)
            url = URI.join(@api_host, url).to_s
        end

        uri  = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)

        # Note: there's also read_timeout and ssl_timeout
        http.open_timeout = 80 # in seconds

        if uri.scheme == 'https'
            http.use_ssl = true
            # FIXME? Risky - see
            # http://www.rubyinside.com/how-to-cure-nethttps-risky-default-https-behavior-4010.html
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.set_debug_output($stderr) if $DEBUG
        SolveBio::logger.debug('API %s Request: %s' % [method.upcase, url])

        request = nil
        if ['POST', 'PUT', 'PATCH'].member?(method.upcase)
            # FIXME? do we need to do something different for
            # PUT and PATCH?
            request = Net::HTTP::Post.new(uri.request_uri)
            request.body = params.to_json
        else
            request = Net::HTTP::Get.new(uri.request_uri)
        end
        @headers.each { |k, v| request.add_field(k, v) }
        request.add_field('Authorization', "Token #{@api_key}") if @api_key
        response = http.request(request)

        status_code = response.code.to_i
        if status_code < 200 or status_code >= 300
            handle_api_error(response)
        end

        return raw ? response.body : JSON.parse(response.body)
    end

    def handle_request_error(e)
        # FIXME: go over this. It is still a rough translation
        # from the python.
        err = e.inspect
        if e.kind_of?(requests.exceptions.RequestException)
            msg = SolveBio::Error::Default_message
        else
            msg = 'Unexpected error communicating with SolveBio. ' +
                "It looks like there's probably a configuration " +
                'issue locally. If this problem persists, let us ' +
                'know at contact@solvebio.com.'
        end
        msg = msg + "\n\n(Network error: #{err}"
        raise SolveBio::Error.new(msg)
    end

    def handle_api_error(response)
        if [400, 401, 403, 404].member?(response.code.to_i)
            raise SolveBio::Error.new(nil, response)
        else
            SolveBio::logger.info("API Error: #{response.msg}")
            raise SolveBio::Error.new(nil, response)
        end
    end

    def self.client
        @@client ||= SolveBio::Client.new()
    end

    def self.request(*args)
        client.request(*args)
    end

end

if __FILE__ == $0
    puts SolveBio::Client.client.headers
    puts SolveBio::Client.client.api_host
    client = SolveBio::Client.new(nil, 'http://google.com')
    response = client.request('http', 'http://google.com') rescue 'no good'
    puts response.inspect
    puts '-' * 30
    response = client.request('http', 'http://www.google.com') rescue 'nope'
    puts response.inspect
    puts '-' * 30
    response = client.request('http', 'https://www.google.com') rescue 'nope'
    puts response.inspect
end
