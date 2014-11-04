# Test Dataset, DatasetField, and Facets
require_relative './helper'
require_relative '../lib/resource/main'

class TestDataset < Test::Unit::TestCase
    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    def test_dataset
        assert(@dataset.member?('id'),
               'Should be able to get id in dataset')

        %w(class_name created_at data_url depository depository_id
           depository_version depository_version_id description
          fields_url full_name name title updated_at url).each do |field|
            assert(@dataset.member?(field),
                   "Should find field #{field} in dataset #{@dataset.id}")
        end

        fields = @dataset.fields()
        dataset_field = fields[:data][0]
        assert(dataset_field.member?('id'),
               'Should be able to get id in list of dataset fields')

        dataset_field2 = SolveBio::DatasetField.retrieve(dataset_field.id)
        assert_equal(dataset_field, dataset_field2,
                     "Retrieving SolveBio::DatasetField id " +
                     "#{dataset_field[:id]} found by all()")

        %w(class_name created_at dataset dataset_id description facets_url
          name updated_at url).each do |field|
            assert(dataset_field.member?(field),
                   "Should find field #{field} in fields #{dataset_field.id}")
        end
        facets = dataset_field.facets()

        # We can get small or large numbers like 0 or 4902851621.0
        assert(facets['total'] >= 0,
               'facets should have a numeric total field >= 0')
    end
end
