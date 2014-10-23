#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'openssl'
require 'net/http'
require 'json'
require_relative 'credentials'
require_relative 'errors'

# import textwrap

# A requests-based HTTP client for SolveBio API resources
class SolveBio::Client

    attr_reader :headers, :api_host
    attr_accessor :api_key

    def initialize(api_key=nil, api_host=nil)
        @api_key = api_key || SolveBio::api_key
        SolveBio::api_key  ||= api_key
        @api_host = api_host || SolveBio::API_HOST
        # Mirroring comments from:
        # http://ruby-doc.org/stdlib-2.1.2/libdoc/net/http/rdoc/Net/HTTP.html
        # gzip compression is used in preference to deflate
        # compression, which is used in preference to no compression.
        @headers  = {
            'Content-Type'    => 'application/json',
            'Accept'          => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent'      => 'SolveBio Ruby Client %s [%s/%s]' % [
                SolveBio::VERSION,
                SolveBio::RUBY_IMPLEMENTATION,
                SolveBio::RUBY_VERSION
            ]
        }
    end

    # FIXME: refactor to not overload params with data and params depending
    # on the method. Also make it possible to do the simpler things that are
    # done in Sample.download

    #
    #    Issues an HTTP Request across the wire via the Ruby 'net/http'
    #    library.
    #   :param method: String an HTTP method: GET, PUT, POST, DELETE, ...
    #   :param url: String the place to connect to. If the url doesn't start
    #         with a protocol (https:// or http://), we'll slap
    #         solvebio.api_host in the front.
    #   :param params: Hash will go into the parameters or data section of
    #         the request as appropriate, depending on the method value.
    #   :param timeout: Fixnum a timeout value in seconds for the request
    #   :param raw: bool whether to return the response encoded to json
    #   :param files: Array File content in the form of a file handle can be
    #          passed in *files* to upload a file. Generally files are passed
    #          via POST requests
    #   :param headers: Hash Custom headers can be provided here;
    #          generally though this will be set correctly by
    #          default dependent on the method type. If the content type
    #          is JSON, we'll JSON-encode params.
    #   :param allow_redirects: bool if set *false* we won't follow any
    #          redirects


    DEFAULT_REQUEST_OPTS = {
        :api_host => SolveBio::API_HOST,
        :files    => nil, # Set to File handle to send a file
        :timeout  => 80,  # Seconds
        :raw      => false
    }

    def request(method, url, opts={})

        opts = DEFAULT_REQUEST_OPTS.merge(opts)
        if not url.start_with?(opts[:api_host])
            url = URI.join(opts[:api_host], url).to_s
        end

        uri  = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)

        # Note: there's also read_timeout and ssl_timeout
        http.open_timeout = opts[:timeout] # in seconds

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
            request = Net::HTTP::Post.new(uri.request_uri)
            request.body = opts[:params].to_json if opts[:params]
        else
            request = Net::HTTP::Get.new(uri.request_uri)
        end
        @headers.each { |k, v| request.add_field(k, v) }
        request.add_field('Authorization', "Token #{@api_key}") if @api_key
        response = http.request(request)

        # FIXME: There's probably gzip decompression built in to
        # net/http. Until I figure out how to get that to work, the
        # below works.
        case response
        when Net::HTTPSuccess then
            begin
                if response['Content-Encoding'].eql?( 'gzip' ) then
                    puts "Performing gzip decompression for response body." if $DEBUG
                    sio = StringIO.new( response.body )
                    gz = Zlib::GzipReader.new( sio )
                    response.body = gz.read()
                end
            rescue Exception
                puts "Error occurred (#{$!.message})" if $DEBUG
                # handle errors
                raise $!.message
            end
        when Net::HTTPRedirection
            location = response['location']
            warn "redirected to #{location}"
            ## fetch(location, limit - 1)
            return JSON.parse(response.body)
        end

        status_code = response.code.to_i
        if status_code < 200 or status_code >= 300
            handle_api_error(response)
        end

        if opts[:raw]
            return response.body
        else
            return JSON.parse(response.body)
        end
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
        raise SolveBio::Error.new(nil, msg)
    end

    def handle_api_error(response)
        if [400, 401, 403, 404].member?(response.code.to_i)
            raise SolveBio::Error.new(response)
        else
            SolveBio::logger.info("API Error: #{response.msg}")
            raise SolveBio::Error.new(response)
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
