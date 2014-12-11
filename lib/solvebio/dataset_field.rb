module SolveBio
    class DatasetField < APIResource
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Update

        def facets(params={})
            response = Client.get(self[:facets_url], {:params => params})
            Util.to_solve_object(response)
        end
    end
end
