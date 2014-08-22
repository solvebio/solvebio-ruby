# -*- coding: utf-8 -*-
require 'uri'
require 'json'
require 'set'

# import urllib

# from utils.tabulate import tabulate

require_relative 'solvebio'
require_relative 'client'
## require_relative 'query'
require_relative 'help'

# from .query import Query
# from .help import open_help

# Add underscore before internal uppercase letters. Also, lowercase
# all letters.
def camelcase_to_underscore(name)
    # Using [[:upper:]] and [[:lower]] should help with Unicode.
    s1 = name.gsub(/(.)([[:upper:]])([[:lower:]]+)/){"#{$1}_#{$2}#{$3}"}
    return (s1.gsub(/([a-z0-9])([[:upper:]])/){"#{$1}_#{$2}"}).downcase
end

# Base class for all SolveBio API resource objects
class SolveBio::SolveObject < Hash

    ALLOW_FULL_NAME_ID = false  # Treat full_name parameter as an ID?

    attr_reader :unsaved_values

    def allow_full_name_id
        self.class.const_get(:ALLOW_FULL_NAME_ID)
    end

    def initialize(id=nil, params={})

        super()
        # store manually updated values for partial updates
        @unsaved_values = Set.new

        if id
            self['id'] = id
        elsif allow_full_name_id and params['full_name']
            self['full_name'] = params['full_name']
            # no ID was provided so temporarily set the id as full_name
            # this will get updated when the resource is refreshed
            self['id'] = params['full_name']
        end
    end

    # @classmethod
    # Used to create a new object from an HTTP response
    def self.construct_from(cls, values)
        instance = cls.new(values['id'])
        instance.refresh_from(values)
        return instance
    end

    def refresh_from(values)
        self.clear()
        @unsaved_values = Set.new
        values.each { |k, v| self[k] = to_solve_object(v) }
    end

    def request(method, url, params=nil)
        response = SolveBio::Client.client.request(method, url, params)
        return to_solve_object(response)
    end

    def inspect
        ident_parts = [self.class]

        if self['id'].kind_of?(Integer)
            ident_parts << "id=#{self['id']}"
        end

        if allow_full_name_id and self['full_name']
            ident_parts << "full_name=#{self['full_name']}"
        end

        return '<%s:%x> JSON: %s' % [ident_parts.join(' '),
                                     self.object_id, self.to_json]

    end

    def str
        # No equivalent of Python's json sort_keys?
        return JSON.pretty_generate(self, :indent => '  ')
        # return self.to_json json.dumps(self, sort_keys=true, indent=2)
    end

    # @property
    def solvebio_id
        return self['id']
    end
end


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
            cls_name = cls_name[0..-1] + 'ie'
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

class SolveBio::ListObject < SolveBio::SolveObject

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
        return to_solve_object(self['data'])
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

        obj = to_solve_object(self['data'][@i])
        @i += 1
        return obj
    end
end


class SingletonAPIResource < SolveBio::APIResource

    # @classmethod
    def self.retrieve(cls)
        return super(SingletonAPIResource, cls).retrieve(nil)
    end

    # @classmethod
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


class ListableAPIResource < SolveBio::APIResource

    # @classmethod
    def self.all(cls, params={})
        url = cls.class_url()
        response = client.request('get', url, params)
        return to_solve_object(response)
    end
end


class SearchableAPIResource < SolveBio::APIResource

    # @classmethod
    def self.search(cls, query='', params={})
        params['q'] = query
        url = cls.class_url()
        response = client.request('get', url, params)
        return to_solve_object(response)
    end
end


class CreateableAPIResource < SolveBio::APIResource

    # @classmethod
    def self.create(cls, params={})
        url = cls.class_url()
        response = client.request('post', url, params)
        return to_solve_object(response)
    end
end

class UpdateableAPIResource < SolveBio::APIResource

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

class DeletableAPIResource < SolveBio::APIResource

    def delete(params={})
        refresh_from(request('delete', instance_url(), params))
        return self
    end
end


# API resources

class SolveBio::User < SingletonAPIResource
end


class SolveBio::Depository < SolveBio::APIResource

    # include CreateableAPIResource
    # include ListableAPIResource
    # include SearchableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\-\.]+$}

    # Supports lookup by ID or full name
    def self.retrieve(cls, id, params={})
        if str.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name: "%s"' % _id
            end
        end

        return SolveBio::APIResource.retrieve(SolveBio::Depository, id,
                                              params)
    end

    def versions(name=nil, params={})
        # construct the depo version full name
        if name
            return DepositoryVersion.retrieve([self['full_name'], name].
                                              join('/'))
        end

        response = client.request('get', self.versions_url, params)
        return to_solve_object(response)
    end

    def help
        open_help(self['full_name'])
    end

end

class SolveBio::DepositoryVersion < SolveBio::APIResource


    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\.]+/[\w\-\.]+$}

    # Supports lookup by full name
    def self.retrieve(cls, id, params={})
        if str.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                parms['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name.'
            end
        end

        return SolveBio::APIResource.retrieve(SolveBio::DepositoryVersion,
                                              id, params)
    end

    def datasets(name=nil, params={})
        if name
            # construct the dataset full name
            return SolveBio::Dataset.retrieve("#{self['full_name']}/#{name}")
        end

        response = SolveBio::Client.client.request('get', self.datasets_url,
                                                   params)
        return response.to_solvebio
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

class SolveBio::Dataset < SolveBio::APIResource

    ## FIXME: delegate methods from these.
    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true

    # Sample matches:
    #  'Clinvar/2.0.0-1/Variants'
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

        return SolveBio::APIResource.retrieve(SolveBio::Dataset, id, params)
    end

    def depository_version
        return DepositoryVersion.retrieve(self['depository_version'])
    end

    def depository
        return SolveBio::Depository.retrieve(self['depository'])
    end

    def fields(name=nil, params={})
        if self.instance_variable.member?(:fields_url)
            raise Exception,
            'Please use Dataset.retrieve({ID}) before doing looking ' +
                'up fields'
        end

        if name
            # construct the field's full_name if a field name is provided
            return DatasetField.retrieve("#{self['full_name']}/#{name}")
        end

        client.request('get', self.fields_url, params).to_solvebio
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

class SolveBio::DatasetField < SolveBio::APIResource

    # include CreateableAPIResource
    # include ListableAPIResource
    # include UpdateableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^([\w\-\.]+/){3}[\w\-\.]+$}

    # Supports lookup by ID or full name
    def self.retrieve(cls, id, params={})
        if str.kind_of?(String)
            _id = id.strip
            id = nil
            if FULL_NAME_REGEX =~ _id
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name.'
            end
        end

        return super(DatasetField, cls).retrieve(id, params={})
    end

    def facets(params={})
        client.request('get', @facets_url, params).to_solvebio
    end

    def help
        facets
    end
end

SolveBio::SolveObject::CONVERSION = {
    'Depository'        => SolveBio::Depository,
    'DepositoryVersion' => SolveBio::DepositoryVersion,
    'Dataset'           => SolveBio::Dataset,
    'DatasetField'      => SolveBio::DatasetField,
    'User'              => SolveBio::User,
    'list'              => SolveBio::ListObject
}

class Hash
    def to_solvebio
        resp = self.dup()
        klass_name = resp['class_name']
        if klass_name.kind_of?(String)
            klass = SolveBio::SolveObject::CONVERSION[klass_name] ||
                SolveBio::SolveObject
        else
            klass = SolveBio::SolveObject
        end
        SolveBio::SolveObject::construct_from(klass, resp)
    end
end

class Array
    def to_solvebio
        return self.map{|i| to_solve_object(i)}
    end
end


def to_solve_object(resp)
    if resp.kind_of?(Array)
        resp.to_solvebio
    elsif not resp.kind_of? SolveBio::SolveObject and resp.kind_of?(Hash)
        resp.to_solvebio
    else
        return resp
    end
end

if __FILE__ == $0
    %w(abc abcDef abc01Def aBcDef a1B2C3 ?Foo Dataset).each do |word|
        puts word + " -> " + camelcase_to_underscore(word)
    end
    puts SolveBio::SolveObject.new.inspect
    puts SolveBio::SolveObject.new(64).inspect

    resp = {
        'class_name' => 'Dataset',
        'data_url'   => 'https://api.solvebio.com/v1/datasets/25/data',
        'depository' => 'ClinVar',
        'depository_id' => 223,
        'depository_version' => 'ClinVar/2.0.0-1',
        'depository_version_id' => 15,
        'description' => '',
        'fields_url' => 'https://api.solvebio.com/v1/datasets/25/fields',
        'full_name' => 'ClinVar/2.0.0-1/Variants',
        'id'  => 25,
        'name' => 'Variants',
        'title' => 'Variants',
        'url' => 'https://api.solvebio.com/v1/datasets/25'
    }
    so = to_solve_object(resp)
    puts so
    puts so.inspect
    puts '-' * 50
    so = resp.to_solvebio
    puts so
    puts so.inspect
    if ARGV[0]
        require_relative './cli/auth.rb'
        include SolveBio::Auth
        login
        puts SolveBio::Dataset.retrieve('Clinvar/2.0.0-1/Variants')
    end
end
