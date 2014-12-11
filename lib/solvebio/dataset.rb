# require_relative 'apiresource'
# require_relative '../query'
# require_relative '../tabulate'

module SolveBio
    class Dataset < APIResource
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::Update
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Delete
        include SolveBio::APIOperations::Help

        def depository
            return Depository.retrieve(self.depository)
        end

        def depository_version
            return DepositoryVersion.retrieve(self.depository_version)
        end

        def fields(name=nil, params={})
            unless self.fields_url
                raise Exception,
                'Please use Dataset.retrieve({ID}) before doing looking ' +
                    'up fields'
            end

            if name
                # construct the field's full_name if a field name is provided
                return DatasetField.retrieve("#{self.full_name}/#{name}")
            end

            result = Client.request('get', self.fields_url)
            results = Util.to_solve_object(result)
            unless results.respond_to?(:tabulate)
                results.define_singleton_method(:tabulate) do |results_hash|
                    ary = results_hash.to_a.map do |fields|
                        [fields['name'], fields['data_type'], fields['description']]
                    end
                    Tabulate.tabulate(ary,
                                    ['Field', 'Data Type', 'Description'],
                                    ['left', 'left', 'left'], true)
                end
            end
            results
        end

        def query(params={})
            params.merge!(:data_url => data_url)
            q = Query.new(self.id, params)

            if params[:filters]
                return q.filter(params[:filters])
            end

            q
        end

        private
        def data_url
            unless self.data_url
                unless self.id
                    raise Exception,
                    'No Dataset ID was provided. ' +
                        'Please instantiate the Dataset ' +
                        'object with an ID or full_name.'
                end
                # automatically construct the data_url from the ID
                puts "AUTOMATICALLY CALC DATA URL"
                puts url
                puts url + '/data'
                return url + '/data'
            end

            return self.data_url
        end

    end
end
