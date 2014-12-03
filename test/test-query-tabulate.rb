$VERBOSE = true
require_relative 'helper'
require_relative '../lib/resource/main'
class TestQueryTabulate < Test::Unit::TestCase
    def check_result_fields(expect, got)
        expect_array = expect.split("\n")
        got_array = got.split("\n")
        assert_equal(expect_array[0..2], got_array[0..2], "Header lines")
        assert_equal(expect_array.size, got_array.size, 'Sizes of results')
        got_array[3...-1].each_with_index do |line, i|
            assert_equal(expect_array[i+3][0..33], line[0..33], "line #{i+3}")
        end
        assert_match(/^[.]{3} [0-9,]+ more results./, got_array[-1])
    end

    def test_query_tabulate
        old_verbose = $VERBOSE
        $VERBOSE=nil
        SolveBio::Tabulate.const_set(:TTY_COLS, 80)
        $VERBOSE=old_verbose
        dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
        results = dataset.query
        expected = <<-EOF

|                       Fields | Data                            |
|------------------------------+---------------------------------|
|            accession_numbers |                                 |
|                approved_name | iris hypoplasia with glaucoma 1 |
|              approved_symbol | IHG1                            |
|                     ccds_ids |                                 |
|                   chromosome | X                               |
|                date_approved | 2001-06-22                      |
|                date_modified | 2012-10-02                      |
|            date_name_changed |                                 |
|          date_symbol_changed |                                 |
|              ensembl_gene_id |                                 |
|           ensembl_id_ensembl |                                 |
|               entrez_gene_id |                                 |
|          entrez_gene_id_ncbi | 3548                            |
|                   enzyme_ids |                                 |
|      gene_family_description |                                 |
|              gene_family_tag |                                 |
|                      hgnc_id | 5954                            |
|                        locus | X                               |
|                  locus_group | phenotype                       |
|     locus_specific_databases |                                 |
|                   locus_type | phenotype only                  |
|     mouse_genome_database_id |                                 |
| mouse_genome_database_id_mgi |                                 |
|                name_synonyms |                                 |
|                 omim_id_ncbi | 308500                          |
|                     omim_ids | 308500                          |
|               previous_names |                                 |
|             previous_symbols | IHG                             |
|                  primary_ids |                                 |
|                   pubmed_ids |                                 |
|   rat_genome_database_id_rgd |                                 |
|                  record_type | Standard                        |
|                   refseq_ids |                                 |
|                  refseq_ncbi |                                 |
|                secondary_ids |                                 |
|                       status | Approved                        |
|                     synonyms |                                 |
|                 ucsc_id_ucsc |                                 |
|           uniprot_id_uniprot |                                 |
|                     vega_ids |                                 |

... 42,928 more results.
EOF
        check_result_fields(expected, results.to_s)
    end
end
