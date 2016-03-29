require File.expand_path('../../helper', __FILE__)

module SolveBio
    class ConversionTest < Test::Unit::TestCase
        def test_class_to_api_name
            klass = SolveBio::DatasetField
            assert_equal('/v1/dataset_fields', klass.url)
            klass = SolveBio::Depository
            assert_equal('/v1/depositories', klass.url)
        end
    end
end
