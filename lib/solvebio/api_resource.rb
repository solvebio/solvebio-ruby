module SolveBio
    class APIResource < SolveObject
        def self.retrieve(id)
            instance = self.new(id)
            instance.refresh()
            instance
        end

        def self.class_to_api_name(cls)
            cls_name = cls.to_s.sub('SolveBio::', '')
            Util.camelcase_to_underscore(Util.pluralize(cls_name))
        end

        def self.class_url(cls)
            cls_name = cls.to_s.sub('SolveBio::', '')
            "/v1/#{class_to_api_name(cls_name)}"
        end

        def refresh
            response = Client.get(instance_url)
            refresh_from(response)
        end

        # Get instance URL by ID or full name (if available)
        def instance_url
            id = self[:id]
            base = APIResource.class_url(self.class)

            if id
                return "#{base}/#{id}"
            else
                msg = 'Could not determine which URL to request: %s instance ' +
                    'has invalid ID: %s' % [self.class, id]
                raise Exception, msg
            end
        end
    end
end
