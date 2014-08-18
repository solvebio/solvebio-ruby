#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require_relative 'solvebio'

class SolveBio::Error < RuntimeError
    Default_message =
        'Unexpected error communicating with SolveBio. ' +
        'If this problem persists, let us know at ' +
        'contact@solvebio.com.'

    def initialize(message=nil, response=nil)
        @json_body = nil
        @status_code = nil
        @message = message or Default_message
        @field_errors = []

        if response
            @status_code = response.status_code
            begin
                @json_body = response.json()
            rescue
                @message = '404 Not Found.'  if response.status_code == 404
                SolveBio.logger.debug(
                    'API Response (%d): No content.' % @status_code)
            else
                @@logger.debug(
                    'API Response (#{@status_code}): #{@json_body}')

                if [400, 401, 403, 404].member?(@status_code)
                    @message = 'Bad request.'

                    if @json_body.member?('detail')
                        @message = '%s' % @json_body['detail']
                    end

                    if @json_body.member?('non_field_errors')
                        @message = '%s.' % \
                            @json_body['non_field_errors'].join(', ')
                    end

                    @json_body.items().each_with_index do |k, v|
                        if ['detail', 'non_field_errors'].member?(k)
                            v = v.join(', ') if v.kind_of?(Array)
                            @field_errors.append('%s (%s)' % [k, v])
                        end
                    end

                    if @field_errors
                        @message += (' The following fields were missing ' +
                            'or invalid: %s' %
                                         @field_errors.join(', '))
                    end
                end
            end
        end
    end

    def str
        @message
    end
end

# Demo code
if __FILE__ == $0
    puts SolveBio::Error.new()
    puts SolveBio::Error.new("Hi there").inspect
    puts SolveBio::Error.new("Hi there").str
    puts SolveBio::Error.new(['Hello, ', 'again.']).inspect
end
