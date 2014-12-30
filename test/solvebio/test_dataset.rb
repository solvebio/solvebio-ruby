require File.expand_path('../../helper', __FILE__)

module SolveBio
    class TestDataset < Test::Unit::TestCase
        def setup
            @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        end

        def test_dataset_retrieval
            assert(@dataset.id,
                   'Should be able to get id in dataset')
            assert(@dataset[:id],
                   'Should be able to get id in dataset')

            %w(class_name created_at data_url depository depository_id
               depository_version depository_version_id description
              fields_url full_name genome_builds is_genomic
              name title updated_at url).each do |field|
                assert(@dataset.respond_to?(field),
                       "Should find field #{field} in dataset #{@dataset.id}")
            end
        end

        def test_dataset_fields
            fields = @dataset.fields
            dataset_field = fields[:data][0]
            assert(dataset_field.id,
                   'Should be able to get id in list of dataset fields')

            dataset_field2 = SolveBio::DatasetField.retrieve(dataset_field.id)
            assert_equal(dataset_field.id, dataset_field2.id,
                         "Retrieving SolveBio::DatasetField id " +
                         "#{dataset_field.id} found by all()")

            %w(class_name created_at dataset dataset_id description facets_url
              name updated_at url).each do |field|
                assert(dataset_field.respond_to?(field),
                       "Should find field #{field} in fields #{dataset_field.id}")
            end
        end

        def test_dataset_facets
            fields = @dataset.fields
            dataset_field = fields[:data][0]
            facets = dataset_field.facets()

            # We can get small or large numbers like 0 or 4902851621.0
            assert(facets['values'].length >= 0)
        end
    end
end
