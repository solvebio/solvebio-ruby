require File.expand_path('../../helper', __FILE__)

module SolveBio
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
            ENV['COLUMNS'] = "66"
            $VERBOSE=old_verbose
            dataset = SolveBio::Dataset.retrieve(TEST_DATASET_NAME)
            results = dataset.query().filter(:hgnc_id => 2396)
            expected = <<-EOF

|                       Fields | Data                            |
|------------------------------+---------------------------------|
|            accession_numbers |                                 |
|                approved_name | crystallin, beta A4             |
|              approved_symbol | CRYBA4                          |
|                     ccds_ids | ["CCDS13841.1"]                 |
|                   chromosome | 22                              |
|                date_approved | 1991-07-25                      |
|                date_modified | 2008-06-10                      |
|            date_name_changed |                                 |
|          date_symbol_changed |                                 |
|              ensembl_gene_id | ENSG00000196431                 |
|           ensembl_id_ensembl | ENSG00000196431                 |
|               entrez_gene_id | 1413                            |
|          entrez_gene_id_ncbi | 1413                            |
|                   enzyme_ids |                                 |
|      gene_family_description |                                 |
|              gene_family_tag |                                 |
|                      hgnc_id | 2396                            |
|                        locus | 22q12.1                         |
|                  locus_group | protein-coding gene             |
|     locus_specific_databases | ["LOVD - Leiden Open Variat ... |
|                   locus_type | gene with protein product       |
|     mouse_genome_database_id | [102716]                        |
| mouse_genome_database_id_mgi | [102716]                        |
|                name_synonyms |                                 |
|                 omim_id_ncbi | 123631                          |
|                     omim_ids | [123631]                        |
|               previous_names |                                 |
|             previous_symbols |                                 |
|                  primary_ids |                                 |
|                   pubmed_ids | ["8999933", "960806"]           |
|   rat_genome_database_id_rgd | 61962                           |
|                  record_type | Standard                        |
|               refseq_id_ncbi | NM_001886                       |
|                   refseq_ids | ["NM_001886"]                   |
|                secondary_ids |                                 |
|                       status | Approved                        |
|                     synonyms |                                 |
|                 ucsc_id_ucsc | uc003acz.4                      |
|           uniprot_id_uniprot | P53673                          |
|                     vega_ids | ["OTTHUMG00000150983"]          |

... No more results.
EOF
            check_result_fields(expected, results.to_s)
        end
    end
end
