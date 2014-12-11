module SolveBio
    class SingletonAPIResource < APIResource
        # def self.class_to_api_name(cls)
        #     cls_name = cls.to_s.sub('SolveBio::', '')
        #     Util.camelcase_to_underscore(cls_name)
        # end

        def self.retrieve
            instance = self.new(nil)
            instance.refresh
            instance
        end

        def self.url
          if self == SingletonAPIResource
            raise NotImplementedError.new('SingletonAPIResource is an abstract class.  You should perform actions on its subclasses (User, Account, etc.)')
          end
          "/v1/#{CGI.escape(class_name.downcase)}"
        end

        def url
          self.class.url
        end
    end
end
