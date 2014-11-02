# Test Depository, DepositoryVersions

require_relative './helper'
class DepositoryTest < Test::Unit::TestCase

    def test_depositories
        depos = SolveBio::Depository.all()
        if depos.total == 0
            skip('no depositories found')
        end
        # print "depos.total %s" % [depos.total]  # compare with python
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

        depo_version_id = depo.versions()[:data][0].id
        depo_version = SolveBio::DepositoryVersion.retrieve(depo_version_id)

        %w(class_name created_at datasets_url depository depository_id
           description full_name id latest name released released_at
           title updated_at url).each do |field|
            assert(depo_version.member?(field),
                   "Should find field #{field} in depo version")
        end
    end
end
