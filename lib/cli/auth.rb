#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'readline'
require 'io/console'

require_relative  '../errors'
require_relative  '../credentials'
require_relative  '../client'

module SolveBio::Auth

    def ask_for_credentials(email=nil)
        while true
            email ||= Readline.readline('Email address: ', true)
            print 'Password (typing will be hidden): '
            password = STDIN.noecho(&:gets).chomp
            puts
            # FIXME: validate email address?
            if email and password
                return email, password
            else
                # FIXME: could say which one is needed.
                print 'Email and password are both required.'
                return nil, nil
            end
        end
    end

    def send_install_report
        require 'socket';
        data = {
            :hostname              => Socket.gethostname(),
            :ruby_version          => SolveBio::RUBY_VERSION,
            :ruby_implementation   => SolveBio::RUBY_IMPLEMENTATION,
            # :platform              => platform(),
            :architecture          => SolveBio::ARCHITECTURE,
            # :processor             => processor(),
        }
        SolveBio::Client.client.request('post',
                                        '/v1/reports/install',
                                        data) rescue nil
    end


    include SolveBio::Credentials

    module_function

    #
    # Prompt user for login information (email/password).
    # Email and password are used to get the user's auth_token key.
    #
    def login(email=nil, password=nil)
        delete_credentials

        email, password = ask_for_credentials email unless
            email and password
        data = {
            :email    => email,
            :password => password
        }

        # FIXME: begin/rescue is a direct translation of the Python
        # code.  Not sure if it's valid here, or what the equivalent
        # is.
        begin
            response = SolveBio::Client.
                client.request('post', '/v1/auth/token', data)
        rescue SolveBio::Error => e
            puts "Login failed: #{e.to_s}"
            return false
        else
            save_credentials(email.downcase, response['token'])
            # reset the default client's auth token
            SolveBio::Client.client.api_key = response['token']
            send_install_report
            puts 'You are now logged-in.'
            return true
        end
    end

    def logout
        if get_credentials()
            delete_credentials()
            SolveBio::Client.client.api_key = nil
            puts 'You have been logged out.'
            return true
        else
            puts 'You are not logged-in.'
            return false
        end
    end

    def whoami
        creds = get_credentials()
        if creds
            puts creds[0]
            return creds[0]
        else
            puts 'You are not logged-in.'
            return nil
        end
    end

end # SolveBio::Auth

# Demo code
if __FILE__ == $0
    include SolveBio::Auth
    case ARGV[0]
    when 'password'
        email, password = ask_for_credentials
        puts email, password
    when 'login'
        login
    when 'logout'
        logout
    when 'whoami'
        whoami
    end
end
