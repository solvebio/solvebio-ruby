# Solvebio API Resource for Samples
# require_relative 'apiresource'
# require_relative 'solveobject'
# require_relative '../errors'

#  Annotations are genomic samples that have been annotated.
#   See https://www.solvebio.com/docs/api/?ruby#annotations
module SolveBio
    class Annotation < APIResource
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::Update
        include SolveBio::APIOperations::Download
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Delete
    end
end
