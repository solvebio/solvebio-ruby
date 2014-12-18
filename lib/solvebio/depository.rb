module SolveBio
    class Depository < APIResource
        #  A depository (or data repository) is like a source code
        #  repository, but for datasets. Depositories have one or more
        #  versions, which in turn contain one or more datasets. Typically,
        #  depositories contain a series of datasets that are compatible with
        #  each other (i.e. they come from the same data source or project).
        include SolveBio::APIOperations::Create
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Search
        include SolveBio::APIOperations::Update
        include SolveBio::APIOperations::Help

        @@permanent_attributes = Set.new([:id, :latest_version])

        # Fields that get shown by tabulate
        LIST_FIELDS = [%w(full_name title description),
                       %w(Name Title Description)]

        def versions(name=nil, params={})
            # construct the depo version full name
            return DepositoryVersion.
                retrieve("#{self['full_name']}/#{name}") if name

            response = Client.request('get', versions_url, {:params => params})
            results = Util.to_solve_object(response)
            unless results.respond_to?(:tabulate)
                results.define_singleton_method(:tabulate) do |results|
                    ary = results.to_a.map do |fields|
                        [fields['full_name'], fields['title'], fields['description']]
                    end
                    Utils::Tabulate.tabulate(ary,
                        ['Depository Version', 'Title', 'Description'],
                        ['left', 'left', 'left'], true)
                end
            end
            results
        end

        def latest_version
            return versions(self[:latest_version].split('/')[-1])
        end

    end
end
