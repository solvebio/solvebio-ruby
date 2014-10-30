require 'test/unit'
require_relative  '../lib/resource/apiresource'

class ConversionTest < Test::Unit::TestCase
    def test_class_to_api_name
        ar = SolveBio::APIResource
        [%w(Annotation annotations),
         %w(DataField  data_fields),
         %w(Depository depositories)].each do |class_name, expect|
            assert_equal(expect, ar.class_to_api_name(class_name))
        end
    end
end
