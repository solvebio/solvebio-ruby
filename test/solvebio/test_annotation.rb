require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestAnnotation < Test::Unit::TestCase
        def check_response(response, expect, msg)
            expect.each do |key, val|
                assert_equal(val, response[key], msg)
            end
        end

        def test_annotation
            if SolveBio.api_host == 'https://api.solvebio.com'
                skip "Annotation testing only on local/dev environments"
            end

            vcf_file = File.join(File.dirname(__FILE__), "data/sample.vcf.gz")
            my_sample = SolveBio::Sample
                          .create('GRCh37', :vcf_file => vcf_file)
            assert(my_sample)

            sample_id = my_sample['id']
            expect = {
                'class_name' => 'Annotation',
                'error_message' => '',
                'sample_id' => sample_id
            }

            response = SolveBio::Annotation.create(:sample_id => sample_id)
            check_response(response, expect,
                           "'Annotation.create(:sample_id=>{#sample_id}")

            ['status', 'user_id', 'created_at', 'updated_at'].each do |field|
                assert(response.respond_to?(field) ,
                       "response has field #{field}")
            end

            all = SolveBio::Annotation.all()
            assert(all.total > 1,
                   "Annotation.all() returns more than one value")

            my_sample.delete
            assert my_sample.deleted
        end
    end
end
