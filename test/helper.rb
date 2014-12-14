require 'solvebio'
require 'solvebio/cli'

require 'test/unit'
require 'webmock/test_unit'
require 'net/http'

ENV['SOLVEBIO_API_HOST'] ||= 'https://api.solvebio.com'

TEST_DATASET_NAME = 'HGNC/1.0.0-1/HGNC'

def local_api?
    ENV['SOLVEBIO_LOCAL_API']
end
