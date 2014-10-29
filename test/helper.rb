require 'test/unit'
require_relative '../lib/main'
require_relative '../lib/solvebio'
ENV['SOLVEBIO_API_HOST'] ||= 'http://api.solvebio.com'

def local_api?
    ENV['SOLVEBIO_API_HOST'].start_with?('http://127.0.0.1')
end
