require_relative 'apiresource'

#  A depository (or data repository) is like a source code
#  repository, but for datasets. Depositories have one or more
#  versions, which in turn contain one or more datasets. Typically,
#  depositories contain a series of datasets that are compatible with
#  each other (i.e. they come from the same data source or project).
class SolveBio::Depository < SolveBio::APIResource

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::SearchableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\-\.]+$}

    # Fields that get shown by tabulate
    TAB_FIELDS = %w(description full_name latest_version name title url)

    # lookup by ID or full name
    def self.retrieve(id, params={})
        if id.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name: "%s"' % _id
            end
        end

        return SolveBio::APIResource.
            retrieve(SolveBio::Depository, id, params)
    end

    def versions_url
        return SolveBio::APIResource.
            retrieve(SolveBio::Depository, self['id'])['versions_url']
    end

    def versions(name=nil, params={})
        # construct the depo version full name
        return SolveBio::DepositoryVersion.
            retrieve("#{self['full_name']}/#{name}") if name

        response = SolveBio::Client.client
            .request('get', versions_url, {:params => params})
        return response.to_solvebio
    end

end
