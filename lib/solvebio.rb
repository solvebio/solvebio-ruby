# SolveBio Ruby bindings
# Learn more at https://www.solvebio.com/docs/api
require 'logger'
require 'fileutils'
require 'json'
require 'logger'
require 'netrc'
require 'openssl'
require 'rest-client'
require 'uri'
require 'addressable/uri'
require 'set'

require 'solvebio/version'
require 'solvebio/util'
require 'solvebio/tabulate'
require 'solvebio/solve_object'
require 'solvebio/api_resource'
require 'solvebio/singleton_api_resource'
require 'solvebio/list_object'
require 'solvebio/client'
require 'solvebio/api_operations'
require 'solvebio/locale'
require 'solvebio/query'
require 'solvebio/filter'
require 'solvebio/acccount'
require 'solvebio/annotation'
require 'solvebio/dataset'
require 'solvebio/dataset_field'
require 'solvebio/depository'
require 'solvebio/depository_version'
require 'solvebio/sample'
require 'solvebio/user'
require 'solvebio/errors'

module SolveBio
    class << self
        attr_accessor :access_token, :api_key, :api_host, :logger
    end

    @api_key       = ENV['SOLVEBIO_API_KEY']
    @access_token  = ENV['SOLVEBIO_ACCESS_TOKEN']
    @api_host      = ENV['SOLVEBIO_API_HOST'] || 'https://api.solvebio.com'

    logfile =
        if ENV['SOLVEBIO_LOGFILE']
            ENV['SOLVEBIO_LOGFILE']
        else
            dir = File::expand_path '~/.solvebio'
            FileUtils.mkdir_p(dir) unless File.exist? dir
            File::expand_path File.join(dir, 'solvebio.log')
        end
    @logger = Logger.new(logfile)

    def self.login(opts={})
        # Clear any existing auth keys
        @access_token = nil
        @api_key = nil

        # Helper method to load credentials from local file in Ruby scripts.
        if opts[:access_token]
            @access_token = opts[:access_token]
        elsif opts[:api_key]
            @api_key = opts[:api_key]
        else
            # creds
            require 'solvebio/cli/credentials'
            _, @api_key = SolveBio::CLI::Credentials.get_credentials
        end

        if @api_key.nil? and @access_token.nil?
            puts "No credentials found. Requests to SolveBio may fail. Use 'solvebio.rb login' to save your API key."
            return false
        end

        return true
    end
end
