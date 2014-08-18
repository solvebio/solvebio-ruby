# -*- coding: utf-8 -*-
require 'uri'
require 'json'
require 'set'

# import urllib
# import re

# from utils.tabulate import tabulate

require_relative 'solvebio'
require_relative 'client'
## require_relative 'query'
require_relative 'help'

# from .query import Query
# from .help import open_help

def camelcase_to_underscore(name)
    # Using [[:upper:]] and [[:lower]] should help with Unicode.
    s1 = name.gsub(/(.)([[:upper:]])([[:lower:]]+)/){"#{$1}_#{$2.downcase}#{$3}"}
    return s1.gsub(/([a-z0-9])([[:upper:]])/){"#{$1}_#{$2.downcase}"}
end


def convert_to_solve_object(resp)
    types = {
        'Depository' => Depository,
        'DepositoryVersion' => DepositoryVersion,
        'Dataset' => Dataset,
        'DatasetField' => DatasetField,
        'User' => User,
        'list' => ListObject
    }

    if resp.kind_of?(Array)
        return resp.map{|i| convert_to_solve_object(i)}
    elsif not resp.kind_of? SolveBio::SolveObject and resp.kind_of?(Hash)
        resp = resp.dup()
        klass_name = resp.get('class_name')
        if instance(klass_name, basestring)
            klass = types.get(klass_name, SolveBio::SolveObject)
        else
            klass = SolveBio::SolveObject
        end
        return klass.construct_from(resp)
    else
        return resp
    end
end

# Base class for all SolveBio API resource objects
class SolveBio::SolveObject < Hash
    ALLOW_FULL_NAME_ID = false  # Treat full_name parameter as an ID?

    attr_reader :unsaved_values

    def initialize(id=nil, params={})

        # store manually updated values for partial updates
        @unsaved_values = Set.new

        if id
            self[:id] = id
        elsif ALLOW_FULL_NAME_ID and params[:full_name]
            self[:full_name] = params[:full_name]
            # no ID was provided so temporarily set the id as full_name
            # this will get updated when the resource is refreshed
            self[:id] = params[:full_name]
        end
    end

    # @classmethod
    # Used to create a new object from an HTTP response
    def self.construct_from(cls, values)
        instance = cls(values.get('id'))
        instance.refresh_from(values)
        return instance
    end

    def refresh_from(values)
        self.clear()
        @unsaved_values = Set.new

        values.each do |k, v|
            super(SolveBio::SolveObject, self).__setitem__(
                k, convert_to_solve_object(v))
        end
    end

    def request(method, url, params=nil)
        response = client.request(method, url, params)
        return convert_to_solve_object(response)
    end

    def inspect
        ident_parts = [self.class]

        if self[:id].kind_of?(Integer)
            ident_parts << "id=#{self[:id]}"
        end

        if ALLOW_FULL_NAME_ID and self[:full_name]
            ident_parts << "full_name=#{self[:full_name]}"
        end

        return '<%s:%x> JSON: %s' % [ident_parts.join(' '),
                                     self.object_id, self.to_json]

    end

    def str
        # No equivalent of sort_keys?
        return JSON.pretty_generate(self, :indent => '  ')
        # return self.to_json json.dumps(self, sort_keys=true, indent=2)
    end

    # @property
    def solvebio_id
        return self[:id]
    end
end


class APIResource < SolveBio::SolveObject

    # @classmethod
    def self.retrieve(cls, id, params={})
        instance = cls.new(id, params={})
        instance.refresh()
        return instance
    end

    def refresh
        refresh_from(request('get', instance_url()))
        return self
    end

    # @classmethod
    def self.class_name(cls)
        if cls == APIResource
            raise NotImplementedError,
            'APIResource is an abstract class.  You should perform ' +
                'actions on its subclasses (e.g. Depository, Dataset)'
        end
        return urllib.quote_plus(cls.__name__).str
    end

    # @classmethod
    def self.class_url(cls)
        cls_name = cls.class_name()
        # pluralize
        if cls_name.end_with?('y')
            cls_name = cls_name[0..-1] + 'ie'
        end
        cls_name = camelcase_to_underscore(cls_name)
        return "/v1/#{cls_name}s"
    end


    # Get instance URL by ID or full name (if available)
    def instance_url
        id = get('id')
        base = class_url()

        if id
            return [base, unicode(id)].join('/')
        else
            raise Exception # ,
               # ( 'Could not determine which URL to request: %s instance ' +
               #  'has invalid ID: %r') % [type(self).__name__, id, 'id']
        end
    end
end

class ListObject < SolveBio::SolveObject

    def all(params={})
        return request('get', self['url'], params)
    end

    def create(params={})
        return request('post', self['url'], params)
    end

    def next_page(params={})
        if self['links']['next']
            return request('get', self['links']['next'], params)
        end
        return nil
    end

    def prev_page(params={})
        if self['links']['prev']
            request('get', self['links']['prev'], params)
        end
        return nil
    end

    def objects
        return convert_to_solve_object(self['data'])
    end

    def __iter__
        @i = 0
        return self
    end

    def next
        if not getattr(self, '_i', nil)
            @i = 0
        end

        if @i >= len(self['data'])
            # get the next page of results
            next_page = self.next_page()
            if ! next_page
                raise StopIteration
            end
            refresh_from(next_page)
            @i = 0
        end

        obj = convert_to_solve_object(self['data'][@i])
        @i += 1
        return obj
    end
end


class SingletonAPIResource < APIResource

    # @classmethod
    def self.retrieve(cls)
        return super(SingletonAPIResource, cls).retrieve(nil)
    end

    # @classmethod
    def self.class_url(cls)
        cls_name = cls.class_name()
        cls_name = camelcase_to_underscore(cls_name)
        return "/v1/%s #{cls_name}"
    end

    def instance_url
        class_url()
    end
end


class ListableAPIResource < APIResource

    # @classmethod
    def self.all(cls, params={})
        url = cls.class_url()
        response = client.request('get', url, params)
        return convert_to_solve_object(response)
    end
end


class SearchableAPIResource < APIResource

    # @classmethod
    def self.search(cls, query='', params={})
        params.update({'q' => query})
        url = cls.class_url()
        response = client.request('get', url, params)
        return convert_to_solve_object(response)
    end
end


class CreateableAPIResource < APIResource

    # @classmethod
    def self.create(cls, params={})
        url = cls.class_url()
        response = client.request('post', url, params)
        return convert_to_solve_object(response)
    end
end

class UpdateableAPIResource < APIResource

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

class DeletableAPIResource < APIResource

    def delete(params={})
        refresh_from(request('delete', instance_url(), params))
        return self
    end
end


# API resources

class User < SingletonAPIResource
end


class Depository

    # include CreateableAPIResource
    # include ListableAPIResource
    # include SearchableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\-\.]+$}

    # @classmethod
    # Supports lookup by ID or full name
    def self.retrieve(cls, id, params={})
        if isinstance(id, unicode) or isinstance(id, str)
            _id = unicode(id).strip()
            id = nil
            if re.match(cls.FULL_NAME_REGEX, _id)
                params.update({'full_name' => _id})
            else
                raise Exception('Unrecognized full name: "%s"' % _id)
            end
        end

        return super(Depository, cls).retrieve(id, params={})
    end

    def versions(name=nil, params={})
        # construct the depo version full name
        if name
            return DepositoryVersion.retrieve([self['full_name'], name].
                                              join('/'))
        end

        response = client.request('get', self.versions_url, params)
        return convert_to_solve_object(response)
    end

    def help
        open_help(self['full_name'])
    end

end

class DepositoryVersion


    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\.]+/[\w\-\.]+$}

    # @classmethod
    # Supports lookup by full name
    def self.retrieve(cls, id, params={})
        if isinstance(id, unicode) or isinstance(id, str)
            _id = unicode(id).strip()
            id = nil
            if re.match(cls.FULL_NAME_REGEX, _id)
                params.update({'full_name' => _id})
            else
                raise Exception('Unrecognized full name.')
            end
        end

        return super(DepositoryVersion, cls).retrieve(id, params={})
    end

    def datasets(name=nil, params={})
        if name
            # construct the dataset full name
            return Dataset.retrieve(
                                    [self['full_name'], name].join '/')
        end

        response = client.request('get', self.datasets_url, params)
        return convert_to_solve_object(response)
    end

    def help
        open_help(self['full_name'])
    end

    # Set the released flag and optional release date and save
    def release(released_at=nil)
        if released_at
            @released_at = released_at
        end
        @released = true
        save()
    end

    # Unset the released flag and save
    def unrelease
        @released = false
        save()
    end
end

class Dataset

    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{/^([\w\-\.]+/){2}[\w\-\.]+$}

    # @classmethod
    # Supports lookup by full name
    def self.retrieve(cls, id, params={})
        if isinstance(id, unicode) or isinstance(id, str)
            _id = unicode(id).strip()
            id = nil
            if re.match(cls.FULL_NAME_REGEX, _id)
                params.update({'full_name' => _id})
            else
                raise Exception('Unrecognized full name.')
            end
        end

        return super(Dataset, cls).retrieve(id, params={})
    end

    def depository_version
        return DepositoryVersion.retrieve(self['depository_version'])
    end

    def depository
        return Depository.retrieve(self['depository'])
    end

    def fields(name=nil, params={})
        if self.instance_variable.member?(:fields_url)
            raise Exception,
            'Please use Dataset.retrieve({ID}) before doing looking ' +
                'up fields'
        end

        if name
            # construct the field's full_name if a field name is provided
            return DatasetField.retrieve(
                                         '/'.join([self['full_name'], name]))
        end

        response = client.request('get', self.fields_url, params)
        return convert_to_solve_object(response)
    end

    def _data_url
        if self.instance_variable.member(:data_url)
            if self.instance_variables.member?('id') or not @id
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

    # def query(self, params={})
    #     q = Query(data_url(), *params={})
    #     if params.get('filters')
    #         return q.filter(params.get('filters'))
    #     end
    #     return q
    # end

    def help
        open_help(self['full_name'])
    end
end

class DatasetField

    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^([\w\-\.]+/){3}[\w\-\.]+$}

    # @classmethod
    # Supports lookup by ID or full name
    def self.retrieve(cls, id, params={})
        if isinstance(id, unicode) or isinstance(id, str)
            _id = unicode(id).strip()
            id = nil
            if re.match(cls.FULL_NAME_REGEX, _id)
                params.update({'full_name' => _id})
            else
                raise Exception, 'Unrecognized full name.'
            end
        end

        return super(DatasetField, cls).retrieve(id, params={})
    end

    def facets(params={})
        response = client.request('get', self.facets_url, params)
        return convert_to_solve_object(response)
    end

    def help
        return self.facets()
    end
end

if __FILE__ == $0
    %w(abc abcDef abc01Def aBcDef a1B2C3 ?Foo).each do |word|
        puts word + " -> " + camelcase_to_underscore(word)
    end
    puts SolveBio::SolveObject.new.inspect
    puts SolveBio::SolveObject.new(64).inspect
end
