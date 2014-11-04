require 'fileutils'
require_relative './helper'

class TestDownload < Test::Unit::TestCase

    def test_sample_download
        # TODO: update to how Python client tests downloads
        all = SolveBio::Sample.all()
        if all.total == 0
            return skip("no samples found to download")
        end
        sample = all['data'][0]
        solve_obj = sample.download(Dir.tmpdir)
        assert_equal(solve_obj['code'], 200,
                     "Download sample file status ok")
        assert(File.exist?(solve_obj['local_filename']),
               "Download sample file on filesystem")
        FileUtils.rm solve_obj['local_filename']
    end
end
