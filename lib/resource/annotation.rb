# Solvebio API Resource for Samples
require_relative 'apiresource'
require_relative 'solveobject'
require_relative '../errors'

#  Annotations are genomic samples that have been annotated.
#   See https://www.solvebio.com/docs/api/?python#annotations
class SolveBio::Annotation < SolveBio::APIResource
    include SolveBio::CreateableAPIResource
    include SolveBio::DeletableAPIResource
    # include SolveBio::DownloadableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::HelpableAPIResource
end

if __FILE__ == $0
    unless SolveBio::API_HOST == 'https://api.solvebio.com'
        SolveBio::SolveObject::CONVERSION = {
            'Annotation' => SolveBio::Annotation,
        } unless defined? SolveBio::SolveObject::CONVERSION
        response = SolveBio::Annotation.all()
        puts response
    end
end
