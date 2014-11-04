# -*- coding: utf-8 -*-
# SolveBio Ruby Client
# ~~~~~~~~~~~~~~~~~~~
#
# This is the Ruby client & library for the SolveBio API.
#
# Have questions or comments? email us at: contact@solvebio.com

require 'logger'
require 'fileutils'

module SolveBio

    VERSION      = '1.6.1'
    @api_key     = ENV['SOLVEBIO_API_KEY']
    logfile      =
        if ENV['SOLVEBIO_LOGFILE']
            ENV['SOLVEBIO_LOGFILE']
        else
            dir = File::expand_path '~/.solvebio'
            mkdir_p(dir) unless File.exist? dir
            File::expand_path File.join(dir, 'solvebio.log')
        end
    @logger      = Logger.new(logfile)
    API_HOST     = ENV['SOLVEBIO_API_HOST'] || 'https://api.solvebio.com'

    # Config info in reports and requests. Encapsulate more?
    RUBY_VERSION         = RbConfig::CONFIG['RUBY_PROGRAM_VERSION']
    RUBY_IMPLEMENTATION  = RbConfig::CONFIG['RUBY_SO_NAME']
    #PLATFORM            = ???
    #PROCESSOR           = ???
    ARCHITECTURE         = RbConfig::CONFIG['arch']

    def logger
        @logger
    end
    def api_key
        @api_key
    end
    def api_key=(value)
        @api_key = value
    end

    module_function :logger, :api_key, :api_key=

end
