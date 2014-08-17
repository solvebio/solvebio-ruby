# -*- coding: utf-8 -*-
# SolveBio Ruby Client
# ~~~~~~~~~~~~~~~~~~~
#
# This is the Ruby client & library for the SolveBio API.
#
# Have questions or comments? email us at: contact@solvebio.com

require 'logger'

module SolveBio

    VERSION      = '1.4.0'
    api_key      = ENV['SOLVEBIO_API_KEY']
    logger   = Logger.new('/tmp/solvebio.log')
    API_HOST     = ENV['SOLVEBIO_API_HOST'] || 'https://api.solvebio.com'

    # Config stuff. Encapsulate more?
    RUBY_VERSION         = RbConfig::CONFIG['RUBY_PROGRAM_VERSION']
    RUBY_IMPLEMENTATION  = RbConfig::CONFIG['RUBY_SO_NAME']
    #PLATFORM            = ???
    #PROCESSOR           = ???
    ARCHITECTURE         = RbConfig::CONFIG['arch']

end
