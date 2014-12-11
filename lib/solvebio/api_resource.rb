module SolveBio
    class APIResource < SolveObject
        def self.retrieve(id)
            instance = self.new(id)
            instance.refresh()
            instance
        end

        def self.class_name
            self.name.split('::')[-1]
        end

        def self.url
            if self == APIResource
                raise NotImplementedError.new('APIResource is an abstract class and has no url.')
            end
            "/v1/#{Util.pluralize(Util.camelcase_to_underscore(class_name))}"
        end

        def url
            unless id = self.id
                raise InvalidRequestError.new("Could not determine which URL to request: #{self.class} instance has invalid ID: #{id.inspect}", 'id')
            end
            "#{self.class.url}/#{id}"
        end

        def refresh
            response = Client.get(url)
            refresh_from(response)
        end
    end
end
