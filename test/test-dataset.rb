# Test Dataset, DatasetField, and Facets
require_relative './helper'
require_relative '../lib/resource/main'

class TestDataStuff < Test::Unit::TestCase

    def test_dataset
        datasets = SolveBio::Dataset.all()
        if datasets.total == 0
            skip('no datasets found')
        end
        ## puts "datasets.total #{datasets.total}" ### compare with python
        dataset = datasets[:data][0]
        assert(dataset.member?('id'),
               'Should be able to get id in dataset')

        dataset2 = SolveBio::Dataset.retrieve(dataset.id)
        assert_equal(dataset2, dataset,
                     "Retrieving dataset id #{dataset.id} found by all()")
        %w(class_name created_at data_url depository depository_id
           depository_version depository_version_id description
          fields_url full_name name title updated_at url).each do |field|
            assert(dataset.member?(field),
                   "Should find field #{field} in dataset #{dataset.id}")
        end

        fields = dataset.fields()
        ## puts "fields.total #{fields.total}" ### compare with python
        if fields.total == 0
            skip("no fields of dataset #{dataset[:name]} found")
        end

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
        ## puts "facets['total'] #{facets['total']}" ## compare with python

        # We can get small or large numbers like 0 or 4902851621.0
        assert(facets['total'] >= 0,
               'facets should have a numeric total field >= 0')
    end
end
