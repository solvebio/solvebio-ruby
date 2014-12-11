# SolveBio Ruby bindings
# Learn more at https://www.solvebio.com/docs/api
require 'logger'
require 'fileutils'
require 'json'
require 'logger'
require 'netrc'
require 'openssl'
require 'rest_client'
require 'uri'
require 'addressable/uri'

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
require 'solvebio/cursor'
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
    @api_key     = ENV['SOLVEBIO_API_KEY']
    @api_host    = ENV['SOLVEBIO_API_HOST'] || 'https://api.solvebio.com'

    logfile      =
        if ENV['SOLVEBIO_LOGFILE']
            ENV['SOLVEBIO_LOGFILE']
        else
            dir = File::expand_path '~/.solvebio'
            FileUtils.mkdir_p(dir) unless File.exist? dir
            File::expand_path File.join(dir, 'solvebio.log')
        end
    @logger = Logger.new(logfile)

    class << self
        attr_accessor :api_key, :api_host, :logger
    end
end
