require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestSampleAccess < Test::Unit::TestCase
        def check_response(response, expect, msg)
            expect.each do |key, val|
                assert_equal(val, response[key], msg)
            end
        end

        def test_insert_delete
            if SolveBio.api_host == 'https://api.solvebio.com'
                skip "Testing only on local/dev environments"
            end

            all = SolveBio::Sample.all
            total = all.total
            vcf_url = 'http://downloads.solvebio.com/vcf/small_sample.vcf.gz'
            expect = {
                'class_name'        => 'Sample',
                'annotations_count' => 0,
                'description'       =>  '',
                'genome_build'      => 'GRCh37',
                'vcf_md5'           => 'a03e39e96671a01208cffd234812556d',
                'vcf_size'          => 12124
            }

            response = SolveBio::Sample.create('GRCh37', :vcf_url => vcf_url)
            check_response(response, expect,
                           'create sample.vcf.gz from url')
            all = SolveBio::Sample.all
            assert_equal(all.total, total + 1, "After uploading an url")
            total = total + 1

            vcf_file = File.join(File.dirname(__FILE__), 'data/sample.vcf.gz')
            response = SolveBio::Sample.create('GRCh37', {:vcf_file => vcf_file})
            expect = {
                'class_name' => 'Sample',
                'annotations_count' => 0,
                'description' => '',
                'genome_build' => 'GRCh37',
                'vcf_md5' => '8d6791b0fcd3458105d3f19467ac8686',
                'vcf_size' => 593
            }

            check_response(response, expect,
                           'create sample.vcf.gz from a file')

            assert_equal(all.total, total, "After uploading a file")

            sample = SolveBio::Sample.retrieve(response.id)
            delete_response = sample.delete
            assert_equal(delete_response.deleted, true,
                             'response.deleted should be true')

            all = SolveBio::Sample.all
            assert_equal(all.total, total, "After deleting a file")
        end
    end
end
