#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'readline'
require 'io/console'

require_relative  'credentials'
require_relative  '../errors'
require_relative  '../client'

include SolveBio::Credentials

module SolveBio::Auth

    # If we've given an email address before, we'll use that
    # as the default address the next time we call login.
    last_email = nil

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

    module_function

    def send_install_report
        require 'socket';
        data = {
            # :solvebio_version      => 'solvebio-ruby ' + SolveBio::version,
            :ruby_version          => SolveBio::RUBY_VERSION,
            :ruby_implementation   => SolveBio::RUBY_IMPLEMENTATION,
            :architecture          => SolveBio::ARCHITECTURE,
        }
        SolveBio::Client.client
            .request('post', '/v1/reports/install',
                     {:payload => data}) rescue nil
    end

    def login_msg(email)
        msg = "\nYou are logged in as %s" % email
        if SolveBio::API_HOST != 'https://api.solvebio.com'
            msg += ' on %s' % SolveBio::API_HOST
        end
        puts msg
    end

    # Prompt user for login information (email/password).
    # Email and password are used to get the user's auth_token key.
    def login(email=nil, api_key=nil)
        if api_key
            old_api_key = SolveBio.api_key
            begin
                SolveBio.api_key = api_key
                response = SolveBio::Client.get('/v1/user', {})
            rescue SolveError => e
                puts 'Login failed: %s' % e.message
                SolveBio.api_key = old_api_key
                return false
            end
            email = response['email']
            save_credentials email, api_key
            send_install_report
            login_msg(email)
            return true
        else
            email = last_email if email
            email, password = ask_for_credentials email
            last_email = email
            data = {
                :email    => email,
                :password => password
            }

            begin
                response = SolveBio::Client.client
                    .request 'post', '/v1/auth/token', {:payload => data}
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
    end

    # If the credentials file has our api host key use that. Otherwise,
    # ask for credentials.
    def login_if_needed
        creds = get_credentials
        if creds
            last_email = creds[0]
            login_msg(last_email)
            return true
        else
            return login(nil, SolveBio.api_key)
        end
    end

    def logout
        if get_credentials
            delete_credentials
            SolveBio::Client.client.api_key = nil
            puts 'You have been logged out.'
            return true
        else
            puts 'You are not logged-in.'
            return false
        end
    end

    def whoami
        creds = get_credentials
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
