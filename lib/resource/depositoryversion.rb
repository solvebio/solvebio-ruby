require_relative 'apiresource'

class SolveBio::DepositoryVersion < SolveBio::APIResource


    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

    ALLOW_FULL_NAME_ID = true

    # FIXME: base off of Depository::FULL_NAME_REGEX
    # Sample matches:
    #  'Clinvar/2.0.0-1'
    FULL_NAME_REGEX = %r{^[\w\.]+/[\w\-\.]+$}

    # Supports lookup by full name
    def self.retrieve(id, params={})
        if id.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name.'
            end
        end

        return SolveBio::APIResource.
            retrieve(SolveBio::DepositoryVersion, id, params)
    end

    def datasets_url(name=nil)
        name ||= self['name']
        "#{self['full_name']}/#{name}"
    end

    def datasets(name=nil, params={})
        if name
            # construct the dataset full name
            return SolveBio::Dataset.retrieve(datasets_url(name))
        end

        response = SolveBio::Client.client
            request('get', datasets_url, {:params => params})
        return response.to_solvebio
    end

    # Set the released flag and optional release date and save
    def release(released_at=nil)
        if released_at
            @released_at = released_at
        end
        @released = true
        save()
    end

    # Unset the released flag and save
    def unrelease
        @released = false
        save()
    end

    # FIXME: is there a better field to sort on?
    def <=>(other)
        require 'trepanning'; debugger
        self.id <=> other.id
    end

end
