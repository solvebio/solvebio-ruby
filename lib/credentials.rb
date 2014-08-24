#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require_relative 'main'
require 'netrc'
require 'uri'

#
#    Raised if the credentials are not found.
#
class CredentialsError < RuntimeError
end

module SolveBio::Credentials

    module_function

    # SolveBio API host -- just the hostname
    def api_host
        URI(SolveBio::API_HOST).host
    end

    def netrc_path
        path =
            if ENV['NETRC_PATH']
                File.join(ENV['NETRC_PATH'], ".netrc")
            else
                Netrc.default_path
            end
        if not File.exist?(path)
            raise IOError, "netrc file #{path} not found"
        end
        path
    end

    #
    #    Returns the tuple user / password given a path for the .netrc file.
    #    Raises CredentialsError if no valid netrc file is found.
    #
    def get_credentials
        n = Netrc.read(netrc_path)
        return n[api_host]
    rescue Netrc::Error => e
        raise CredentialsError, "Could not read .netrc file: #{e}"
    end
    module_function :get_credentials

    def delete_credentials
        n = Netrc.read(netrc_path)
        n.delete(api_host)
        n.save
    end

    def save_credentials(email, api_key)
        n = Netrc.read(netrc_path)
        # Overwrites any existing credentials
        n[api_host] = email, api_key
        n.save
    end
end

# Demo code
if __FILE__ == $0
    include SolveBio::Credentials
    puts "authentication: #{netrc_path}"
    puts "creds", get_credentials
end
