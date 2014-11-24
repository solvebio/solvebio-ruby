# Cheet sheet for SolveBio API
require 'solvebio'

# Load the Dataset object
dataset = SolveBio::Dataset.retrieve('ClinVar/2.0.0-1/Variants')

# Print the Dataset
puts dataset.query()

# Get help (fields/facets)
dataset.help()

# Query the dataset (filterless)
q = dataset.query()

filters = SolveBio::Filter.new :gene_symbols => "BRCA2"

puts dataset.query(:filters => filters)

# Multiple keyword filter (boolean 'or')
filters = SolveBio::Filter.new :gene_symbols => "BRCA2"
filters |= SolveBio::Filter.new :gene_symbols => "BRCA1"

# Same as above 'or' in one go using 'in'
filters = SolveBio::Filter.new :gene_symbols__in => ["BRCA2", "BRCA1"]

puts dataset.query(:filters => filters)

# Range filter. Like 'in' for a contiguous numeric range
dataset.query(:filters =>
              SolveBio::RangeFilter.new('hg38', "13", 32_200_000, 32_200_500))
