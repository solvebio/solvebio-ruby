require 'test/unit'
require_relative '../lib/solvebio'

def local_api?
    ENV['SOLVEBIO_API_HOST'].start_with?('http://127.0.0.1')
end
