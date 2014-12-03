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

     # Fields that get shown by tabulate
    TAB_FIELDS = %w(datasets_url depository description full_name
                   latest url)

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
                     .request('get', datasets_url, {:params => params})
        results = response.to_solvebio
        unless results.respond_to?(:tabulate)
            results.define_singleton_method(:tabulate) do |results|
                ary = results.to_a.map do |fields|
                    [fields['full_name'], fields['title'], fields['description']]
                end
                SolveBio::Tabulate.tabulate(ary,
                                            ['Field', 'Title', 'Description'],
                                            ['left', 'left', 'left'], true)
            end
        end
        results
    end

    def <=>(other)
        self[:full_name] <=> other[:full_name]
    end

end
