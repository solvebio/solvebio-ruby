# -*- coding: utf-8 -*-
require_relative 'solvebio'
require_relative 'client'

class SolveBio::APIResource < SolveBio::SolveObject

    # @classmethod
    def self.retrieve(cls, id, params={})
        instance = cls.new(id, params)
        instance.refresh()
        return instance
    end

    def refresh
        refresh_from(request('get', instance_url()))
        return self
    end

    # @classmethod
    # def self.class_name(cls)
    #     if cls == SolveBio::APIResource
    #         raise NotImplementedError,
    #         'SolveBio::APIResource is an abstract class.  You should perform ' +
    #             'actions on its subclasses (e.g. SolveBio::Depository, Dataset)'
    #     end
    #     return urllib.quote_plus(cls.__name__).str
    # end

    def self.class_url(cls)
        # cls_name = cls.class_name()
        cls_name = cls.to_s.sub('SolveBio::', '')
        # pluralize
        if cls_name.end_with?('y')
            cls_name = cls_name[0..-2] + 'ie'
        end
        cls_name = camelcase_to_underscore(cls_name)
        return "/v1/#{cls_name}s"
    end


    # Get instance URL by ID or full name (if available)
    def instance_url
        id = self['id']
        base = SolveBio::APIResource.class_url(self.class)

        if id
            return "#{base}/#{id}"
        else
            msg = 'Could not determine which URL to request: %s instance ' +
                'has invalid ID: %s' % [self.class, id]
            raise Exception, msg
        end
    end
end

module SolveBio::ListableAPIResource

    def self.included base
        base.extend ClassMethods
    end

    module ClassMethods
        def all(params={})
            url = SolveBio::APIResource.class_url(self)
            response = SolveBio::Client.client.request('get', url, params)
            return response.to_solvebio
        end
    end
end


module SolveBio::SearchableAPIResource

    def self.included base
        base.extend ClassMethods
    end

    module ClassMethods
        def search(query='', params={})
            params['q'] = query
            url = SolveBio::APIResource.class_url(self)
            response = SolveBio::Client.client.request('get', url, params)
            return response.to_solvebio
        end
    end
end

module SolveBio::CreateableAPIResource

    def self.included base
        base.extend ClassMethods
    end

    module ClassMethods
        def create(params={})
           url = SolveBio::APIResource.class_url(self)
            response = SolveBio::Client.client.request('post', url, params)
            return to_solve_object(response)
        end
    end
end

module SolveBio::UpdateableAPIResource

    def self.included base
        base.extend ClassMethods
    end

    module ClassMethods
        def save
            refresh_from(request('patch', instance_url(),
                                 serialize(self)))
            return self
        end

        def serialize(obj)
            params = {}
            if obj.unsaved_values
                obj.unsaved_values.each do |k|
                    next if k == 'id'
                    params[k] = getattr(obj, k) or ''
                end
            end
            return params
        end
    end
end

class SolveBio::DeletableAPIResource
    def self.included base
        base.extend ClassMethods
    end

    module ClassMethods

        def delete(params={})
            refresh_from(request('delete', instance_url(), params))
            return self
        end
    end
end
