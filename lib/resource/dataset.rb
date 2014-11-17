require_relative 'apiresource'
require_relative '../query'
require_relative '../tabulate'

class SolveBio::Dataset < SolveBio::APIResource

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

    ALLOW_FULL_NAME_ID = true

    # FIXME: base off of DepositoryVersion::FULL_NAME_REGEX
    # Sample matches:
    #  'Clinvar/2.0.0-1/Variants'
    #  'omim/0.0.1-1/omim'
    FULL_NAME_REGEX = %r{^([\w\-\.]+/){2}[\w\-\.]+$}

    # Dataset lookup by full string name
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
            retrieve(SolveBio::Dataset, id, params)
    end

    def depository_version
        return SolveBio::DepositoryVersion.
            retrieve(self['depository_version'])
    end

    def depository
        return SolveBio::Depository.retrieve(self['depository'])
    end

    def fields(name=nil, params={})
        unless self['fields_url']
            raise Exception,
            'Please use Dataset.retrieve({ID}) before doing looking ' +
                'up fields'
        end

        if name
            # construct the field's full_name if a field name is provided
            return DatasetField.retrieve("#{self['full_name']}/#{name}")
        end

        result = SolveBio::Client.
                   client.request('get', self['fields_url'])
        results = result.to_solvebio
        unless results.respond_to?(:tabulate)
            results.define_singleton_method(:tabulate) do |results_hash|
                ary = results_hash.to_a.map do |fields|
                    [fields['name'], fields['data_type'], fields['description']]
                end
                SolveBio::Tabulate.tabulate(ary,
                                            ['Field', 'Data Type', 'Description'],
                                            ['left', 'left', 'left'], true)
            end
        end
        results
    end

    def query(params={})
        q = SolveBio::Query.new(self['id'], params)

        if params[:filters]
            return q.filter(params[:filters])
        end
        return q
    end

    private
    def data_url
        unless self['data_url']
            unless self['id']
                raise Exception,
                'No Dataset ID was provided. ' +
                    'Please instantiate the Dataset ' +
                    'object with an ID or full_name.'
            end
            # automatically construct the data_url from the ID
            return instance_url() + '/data'
        end
        return self['data_url']
    end

end
