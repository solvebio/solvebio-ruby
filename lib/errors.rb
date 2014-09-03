#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require_relative 'main'

class SolveBio::Error < RuntimeError
    Default_message =
        'Unexpected error communicating with SolveBio. ' +
        'If this problem persists, let us know at ' +
        'contact@solvebio.com.'

    attr_reader :json_body
    attr_reader :status_code
    attr_reader :message
    attr_reader :field_errors

    def initialize( response=nil, message=nil)
        @json_body = nil
        @status_code = nil
        @message = message or Default_message
        @field_errors = []

        if response
            @status_code = response.code.to_i
            @message     = response.message
            begin
                @json_body = JSON.parse(response.body)
            rescue
                @message = '404 Not Found.' if @status_code == 404
                SolveBio.logger.debug(
                    "API Response (%d): No content." % @status_code)
            else
                SolveBio.logger.debug(
                    "API Response (#{@status_code}): #{@json_body}")

                if [400, 401, 403, 404].member?(@status_code)
                    @message = 'Bad request.'

                    if @json_body.member?('detail')
                        @message = '%s' % @json_body['detail']
                    end

                    if @json_body.member?('non_field_errors')
                        @message = '%s.' % \
                            @json_body['non_field_errors'].join(', ')
                    end

                    @json_body.each do |k, v|
                        unless ['detail', 'non_field_errors'].member?(k)
                            v = v.join(', ') if v.kind_of?(Array)
                            @field_errors << ('%s (%s)' % [k, v])
                        end
                    end

                    unless @field_errors.empty?
                        @message += (' The following fields were missing ' +
                            'or invalid: %s' %
                                         @field_errors.join(', '))
                    end
                end
            end
        end
        self
    end

    def to_s
        @message
    end
end

# Demo code
if __FILE__ == $0
    puts SolveBio::Error.new
    puts SolveBio::Error.new(nil, 'Hi there').inspect
    puts SolveBio::Error.new(nil, 'Hi there').to_s
    puts SolveBio::Error.new(nil, ['Hello, ', 'again.']).inspect

    require 'net/http'
    response = Net::HTTPUnauthorized.new('HTTP 1.1', '404', 'No creds')
    puts SolveBio::Error.new(response).to_s

end
