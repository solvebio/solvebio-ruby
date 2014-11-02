require 'test/unit'
ENV['SOLVEBIO_API_HOST'] ||= 'http://api.solvebio.com'
require_relative '../lib/main'

def local_api?
    ENV['SOLVEBIO_LOCAL_API']
end
