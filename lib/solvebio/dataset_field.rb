# require_relative 'apiresource'

module SolveBio
    class DatasetField < APIResource
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Update

        def facets(params={})
            response = Client.request 'get', self[:facets_url], {:params => params}
            response.to_solvebio(SolveObject)
        end
    end
end
