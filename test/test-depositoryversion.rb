# Test DepositoryVersion

require_relative './helper'
require_relative '../lib/resource/main'
class TestDepository < Test::Unit::TestCase

    def test_depositoryversion
        dvs = SolveBio::DepositoryVersion.all
        dv = dvs[:data][0]
        assert(dv.member?('id'),
               'Should be able to get id in depositoryversion')

        dv2 = SolveBio::DepositoryVersion.retrieve(dv.id)
        assert_equal(dv, dv2,
                         "Retrieving dataset id #{dv.id} found by all()")
        %w(class_name created_at datasets_url depository depository_id
           description full_name id latest name is_released released_at
           title updated_at url).each do |field|
            assert(dv.member?(field),
                   "Should find field #{field} in depo version")
        end

        expected_start = '
 Fields       | Data                                                           |
--------------+----------------------------------------------------------------|
 datasets_url |
'[1..-2]
        assert(dv.to_s.start_with?(expected_start), 'depositoryversion tabulate')
    end
end
