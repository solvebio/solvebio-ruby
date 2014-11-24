# Test Depository

require_relative './helper'
require_relative '../lib/resource/main'
class TestDepository < Test::Unit::TestCase

    def test_depositories
        depos = SolveBio::Depository.all

        depo = depos[:data][0]
        assert(depo.member?('id'),
               'Should be able to get id in depository')

        depo2 = SolveBio::Depository.retrieve(depo.id)
        assert_equal(depo, depo2,
                         "Retrieving dataset id #{depo.id} found by all()")

        %w(class_name created_at description external_resources
           full_name id is_private is_restricted latest_version
           latest_version_id name title updated_at url versions_count
           versions_url).each do |field|
            assert(depo.member?(field),
                   "Should find field #{field} in depo #{depo.id}")
        end

        expected_start = '
 Fields         | Data                                                         |
----------------+--------------------------------------------------------------|
 description    |
'[1..-2]
        assert(depo.to_s.start_with?(expected_start), 'depository tabulate')
    end
end
