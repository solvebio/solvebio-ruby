# Test Dataset, DatasetField, and Facets
require_relative './helper'
require_relative '../lib/resource/main'

class TestDataset < Test::Unit::TestCase
    def setup
        @dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
    end

    def test_dataset_retrieval
        assert(@dataset.member?('id'),
               'Should be able to get id in dataset')

        %w(class_name created_at data_url depository depository_id
           depository_version depository_version_id description
          fields_url full_name genome_builds is_genomic
          name title updated_at url).each do |field|
            assert(@dataset.member?(field),
                   "Should find field #{field} in dataset #{@dataset.id}")
        end
    end

    def test_dataset_fields
        fields = @dataset.fields
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

        expected = '
| Field                        | Data Type   | Description   |
|------------------------------+-------------+---------------|
| accession_numbers            | string      |               |
| approved_name                | string      |               |
| approved_symbol              | string      |               |
| ccds_ids                     | string      |               |
| chromosome                   | string      |               |
| date_approved                | date        |               |
| date_modified                | date        |               |
| date_name_changed            | date        |               |
| date_symbol_changed          | date        |               |
| ensembl_gene_id              | string      |               |
| ensembl_id_ensembl           | string      |               |
| entrez_gene_id               | string      |               |
| entrez_gene_id_ncbi          | string      |               |
| enzyme_ids                   | string      |               |
| gene_family_description      | string      |               |
| gene_family_tag              | string      |               |
| hgnc_id                      | long        |               |
| locus                        | string      |               |
| locus_group                  | string      |               |
| locus_specific_databases     | string      |               |
| locus_type                   | string      |               |
| mouse_genome_database_id     | long        |               |
| mouse_genome_database_id_mgi | long        |               |
| name_synonyms                | string      |               |
| omim_id_ncbi                 | string      |               |
| omim_ids                     | long        |               |
| previous_names               | string      |               |
| previous_symbols             | string      |               |
| pubmed_ids                   | string      |               |
| rat_genome_database_id_rgd   | long        |               |
| record_type                  | string      |               |
| refseq_id_ncbi               | string      |               |
| refseq_ids                   | string      |               |
| specialist_database_id       | string      |               |
| specialist_database_links    | string      |               |
| status                       | string      |               |
| synonyms                     | string      |               |
| ucsc_id_ucsc                 | string      |               |
| uniprot_id_uniprot           | string      |               |
| vega_ids                     | string      |               |
'
        assert_equal("#{fields}", expected[1...-1],
                     'tabulated dataset fields')
    end

    def test_dataset_facets
        fields = @dataset.fields
        dataset_field = fields[:data][0]
        facets = dataset_field.facets()

        # We can get small or large numbers like 0 or 4902851621.0
        assert(facets['total'] >= 0,
               'facets should have a numeric total field >= 0')
    end
end
