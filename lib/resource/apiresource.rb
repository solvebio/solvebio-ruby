# -*- coding: utf-8 -*-
require 'uri'
require_relative 'solveobject'
require_relative '../main'
require_relative '../client'

class SolveBio::APIResource < SolveBio::SolveObject

    def self.retrieve(cls, id, params={})
        instance = cls.new(id, params)
        instance.refresh()
        return instance
    end

    def refresh
        refresh_from request('get', instance_url)
        return self
    end

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

module SolveBio::HelpableAPIResource

    attr_reader :have_launchy

    @@have_launchy = false
    begin
        @@have_launchy = require 'launchy'
    rescue LoadError
    end

    def self.included base
        base.send :include, InstanceMethods
    end

    module InstanceMethods
        def help
            open_help(self['full_name'])
        end
    end

    def open_help(path)
        url = URI::join('https://www.solvebio.com/', path)
        if @@have_launchy
            Launchy.open(url)
        else
            puts('The SolveBio Ruby client needs the "launchy" gem to ' +
                 "open help url: #{url.to_s}")
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

module SolveBio::SingletonAPIResource

    def self.retrieve(cls)
        return super(SingletonAPIResource, cls).retrieve(nil)
    end

    def self.class_url(cls)
        # cls_name = cls.class_name()
        cls_name = cls.to_s.sub('SolveBio::', '')
        cls_name = camelcase_to_underscore(cls_name)
        return "/v1/%s #{cls_name}"
    end

    def instance_url
        class_url()
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

# Demo code
if __FILE__ == $0
    include SolveBio::HelpableAPIResource
    if @@have_launchy
        open_help('docs')
        sleep 1
    else
        puts "Don't have launchy"
    end
end
