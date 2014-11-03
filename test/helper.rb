require 'test/unit'
ENV['SOLVEBIO_API_HOST'] ||= 'https://api.solvebio.com'
require_relative '../lib/main'

TEST_DATASET_NAME = 'HGNC/1.0.0-1/HGNC'


def local_api?
    ENV['SOLVEBIO_LOCAL_API']
end
