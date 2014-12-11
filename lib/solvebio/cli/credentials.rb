#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class CredentialsError < RuntimeError
end

module SolveBio
    module CLI
        module Credentials
            module_function
            def api_host
                Addressable::URI.parse(SolveBio.api_host).host
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

            def get_credentials
                begin
                    n = Netrc.read(netrc_path)
                    return n[api_host]
                rescue Netrc::Error => e
                    raise CredentialsError, "Could not read credentials file: #{e}"
                end
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
    end
end
