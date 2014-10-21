require_relative 'apiresource'

class SolveBio::DatasetField < SolveBio::APIResource

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^([\w\-\.]+/){3}[\w\-\.]+$}

    # Supports lookup by ID or full name
    def self.retrieve(id, params={})
        if id.kind_of?(String)
            _id = id.strip
            id = nil
            if FULL_NAME_REGEX =~ _id
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name.'
            end
        end

        return SolveBio::APIResource.
            retrieve(SolveBio::DatasetField, id, params)
    end

    def facets(params={})
        response = SolveBio::Client.
            client.request('get', self[:facets_url], params)
        return response.to_solvebio
    end

    def help
        facets
    end
end
