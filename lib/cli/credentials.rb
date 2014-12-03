#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Deals with reading a SolveBio's netrc-style credentials file
require_relative '../main'
require 'netrc'
require 'fileutils'
require 'addressable/uri'

#
#  Exception which can br raised if the credentials are not found.
#
class CredentialsError < RuntimeError
end

module SolveBio::Credentials

    module_function

    # SolveBio API host -- just the hostname
    def api_host
        Addressable::URI.parse(SolveBio::API_HOST).host
    end

    def netrc_path

        raise IOError, "$HOME is not set and is needed for SolveBio credentials" unless
            ENV['HOME']

        path = File.join(ENV['HOME'], '.solvebio', 'credentials')

        dirname = File.dirname(path)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

        # create an empty credentials file if it doesn't exist
        FileUtils.touch path unless File.exist? path
        FileUtils.chmod 0600, path
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
        raise CredentialsError, "Could not read credentials file: #{e}"
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
