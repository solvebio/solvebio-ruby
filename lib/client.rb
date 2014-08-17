#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'uri'

require_relative 'solvebio'
require_relative 'credentials'

# import json
# import requests
# import textwrap
# from requests.auth import AuthBase

# Custom auth handler for SolveBio API token authentication
class SolveBio::TokenAuth # < AuthBase

    include SolveBio::Credentials

    def new(token=nil)
        @token = token or self._get_api_key()
    end

    def __call__(r)
        if @token
            r.headers['Authorization'] = 'Token %s' % self.token
            return r
        end
    end

    def inspect
        return '<SolveTokenAuth %s>' % @token
    end


    # Helper function to get the current user's API key or nil.
    def _get_api_key
        return solvebio.api_key if solvebio.api_key
        return get_credentials()[1] rescue nil
    end
end


# A requests-based HTTP client for SolveBio API resources
class SolveBio::Client

    def new(api_key=nil, api_host=nil)
        @api_key = api_key
        @api_host = api_host || SolveBio::api_host
        @headers = {
            'Content-Type'    => 'application/json',
            'Accept'          => 'application/json',
            'Accept-Encoding' => 'gzip,deflate',
            'User-Agent'      => 'SolveBio Ruby Client %s [Ruby %s/%s]' % [
                SolveBio::VERSION,
                SolveBio::RUBY_IMPLEMENTATION,
                SolveBio::RUBY_VERSION
            ]
        }
    end

    def request(method, url, params=nil, raw=false)
        if ['POST', 'PUT', 'PATCH'].member?(method.upcase)
            # use only the data payload for write requests
            data = json.dumps(params)
            params = nil
        else
            data = nil
        end

        if not @api_host
            raise SolveBio::Error.new(message='No SolveBio API host is set')
        elsif not url.start_with?(@api_host)
            url = URI.join(@api_host, url)
        end

        logger.debug('API %s Request: %s' % [method.upcase, url])

        begin
            response = requests.request(method=method.upcase,
                                        url=url,
                                        params=params,
                                        data=data,
                                        auth=SolveTokenAuth(self._api_key),
                                        verify=True,
                                        timeout=80,
                                        headers=self.headers)
        rescue => e
            _handle_request_error(e)
        end

        if not (200 <= response.status_code and response.status_code < 300)
            _handle_api_error(response)
        end

        if raw
            return response
        end

        return response.json()
    end

    def _handle_request_error(e)
        err = e.inspect
        if e.kind_of?(requests.exceptions.RequestException)
            msg = SolveBio::Error::Default_message
        else
            msg = ("Unexpected error communicating with SolveBio. "
                   "It looks like there's probably a configuration "
                   "issue locally. If this problem persists, let us "
                   "know at contact@solvebio.com.")
        end
        msg = msg + "\n\n(Network error: #{err}"
        raise SolveBio::Error.new(message=msg)
    end

    def _handle_api_error(response)
        if [400, 401, 403, 404].member?(response.status_code)
            raise SolveBio::Error.new(response=response)
        else
            logger.info('API Error: %d' % response.status_code)
            raise SolveBio::Error.new(response=response)
        end
    end
end

client = SolveBio::Client.new()
