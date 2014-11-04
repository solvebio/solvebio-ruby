require 'fileutils'
require_relative './helper'

class TestSampleDownload < Test::Unit::TestCase

    def test_sample_download
        if SolveBio::API_HOST == 'https://api.solvebio.com'
            skip "Testing only on local/dev environments"
        end

        vcf_file = File.join(File.dirname(__FILE__), 'data/sample.vcf.gz')
        sample = SolveBio::Sample.create('GRCh37', {:vcf_file => vcf_file})
        response = sample.download()
        assert_equal(response['code'], 200,
                     "Download sample file status ok")
        assert(File.exist?(response['filename']),
               "Download sample file on filesystem")
        FileUtils.rm response['filename']
    end
end
