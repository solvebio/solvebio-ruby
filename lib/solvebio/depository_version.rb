module SolveBio
    class DepositoryVersion < APIResource
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Update
        include SolveBio::APIOperations::Help

        # Fields that get shown by tabulate
        LIST_FIELDS = [%w(full_name title description),
                       %w(Name Title Description)]

        def datasets_url(name=nil)
            name ||= self['name']
            "#{self['full_name']}/#{name}"
        end

        def datasets(name=nil, params={})
            return Dataset.retrieve(datasets_url(name)) if name

            response = Client.request('get', datasets_url, {:params => params})
            results = Util.to_solve_object(response)
            unless results.respond_to?(:tabulate)
                results.define_singleton_method(:tabulate) do |results|
                    ary = results.to_a.map do |fields|
                        [fields['full_name'], fields['title'], fields['description']]
                    end
                    Tabulate.tabulate(ary,
                        ['Field', 'Title', 'Description'],
                        ['left', 'left', 'left'], true)
                end
            end

            results
        end

        def <=>(other)
            self[:full_name] <=> other[:full_name]
        end

        def changelog(version=nil, params={})
            unless self.respond_to?(:changelog_url)
                unless self.respond_to?(:id)
                    raise Exception,
                    'No Dataset ID was provided. ' +
                        'Please instantiate the Dataset ' +
                        'object with an ID or full_name.'
                end
                # automatically construct the data_url from the ID
                if version
                  self.changelog_url = url + '/changelog/' + version
                else
                  self.changelog_url = url + '/changelog'
                end
            end

            params.merge!(:changelog_url => self.changelog_url)
            return Client.request('get', self.changelog_url, params)
        end
    end
end
