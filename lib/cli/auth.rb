#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'readline'
require 'io/console'

require_relative  '../solvebio'
require_relative  '../errors'
require_relative  '../credentials'

module SolveBio::Auth

    def ask_for_credentials
        while true
            email = Readline.readline('Email address: ', true)
            print 'Password (typing will be hidden): '
            password = STDIN.noecho(&:gets)
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
        include SolveBio::Platform
        data = {
            :hostname              => Socket.gethostname(),
            :ruby_version          => SolveBio::RUBY_VERSION,
            :ruby_implementation   => SolveBio::RUBY_IMPLEMENTATION,
            # :platform              => platform(),
            :architecture          => SolveBio::ARCHITECTURE,
            # :processor             => processor(),
        }
        begin
            client.request('post', '/v1/reports/install', data)
        rescue
        end
    end


    include SolveBio::Credentials

    #
    # Prompt user for login information (email/password).
    # Email and password are used to get the user's auth_token key.
    #
    def login(args)
        delete_credentials()

        email, password = ask_for_credentials
        data = {
            :email    => email,
            :password => password
        }
        begin
            response = client.request('post', '/v1/auth/token', data)
        rescue SolveBio::Error => e
                puts "Login failed: #{e}"
        else
            save_credentials(email.downcase, response['token'])
            # reset the default client's auth token
            SolveBio::api_key = response['token']
            send_install_report
            puts 'You are now logged-in.'
        end
    end

    def logout(args)
        if get_credentials()
            delete_credentials()
            client.auth = nil
            puts 'You have been logged out.'
        else
            puts 'You are not logged-in.'
        end
    end

    def whoami(args)
        creds = get_credentials()
        if creds
            puts creds[0]
        else
            puts 'You are not logged-in.'
        end
    end

end # SolveBio::Auth

# Demo code
if __FILE__ == $0
    include SolveBio::Auth
    if ARGV[0] == 'password'
        email, password = ask_for_credentials
    end
end
