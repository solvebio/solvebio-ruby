# -*- coding: utf-8 -*-
# from utils.tabulate import tabulate

require_relative 'solveobject'
require_relative 'apiresource'
require_relative 'client'
## require_relative 'query'
require_relative 'help'

# from .query import Query

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

    # FIXME: this is still how it's done in Python
    def __iter__
        @i = 0
        return self
    end

    # FIXME: this is still how it's done in Python
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


# API resources

class SolveBio::User < SingletonAPIResource
end


class SolveBio::Depository < SolveBio::APIResource

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::SearchableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\-\.]+$}

    # lookup by ID or full name
    def self.retrieve(id, params={})
        if id.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                params['full_name'] = _id
            else
                raise Exception, 'Unrecognized full name: "%s"' % _id
            end
        end

        return SolveBio::APIResource.
            retrieve(SolveBio::Depository, id, params)
    end

    def versions_url
        return SolveBio::APIResource.
            retrieve(SolveBio::Depository, self['id'])['versions_url']
    end

    def versions(name=nil, params={})
        # construct the depo version full name
        return SolveBio::DepositoryVersion.
            retrieve("#{self['full_name']}/#{name}") if name

        response = SolveBio::Client.
            client.request('get', versions_url, params)
        return response.to_solvebio
    end

end

class SolveBio::DepositoryVersion < SolveBio::APIResource


    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

    ALLOW_FULL_NAME_ID = true
    FULL_NAME_REGEX = %r{^[\w\.]+/[\w\-\.]+$}

    # Supports lookup by full name
    def self.retrieve(cls, id, params={})
        if id.kind_of?(String)
            _id = id.strip
            id = nil
            if _id =~ FULL_NAME_REGEX
                params['full_name'] = _id
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

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource
    include SolveBio::HelpableAPIResource

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
        return SolveBio::DepositoryVersion.
            retrieve(SolveBio::Dataset, self['depository_version'])
    end

    def depository
        return SolveBio::Depository.retrieve(self['depository'])
    end

    def fields(name=nil, params={})
        unless self['fields_url']
            raise Exception,
            'Please use Dataset.retrieve({ID}) before doing looking ' +
                'up fields'
        end

        if name
            # construct the field's full_name if a field name is provided
            return DatasetField.retrieve("#{self['full_name']}/#{name}")
        end

        SolveBio::Client.
            client.request('get', self['fields_url']).to_solvebio
    end

    # def query(self, params={})
    #     q = Query(data_url(), *params={})
    #     if params.get('filters')
    #         return q.filter(params.get('filters'))
    #     end
    #     return q
    # end

    private
    def data_url
        unless self['data_url']
            unless self['id']
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

end

class SolveBio::DatasetField < SolveBio::APIResource

    include SolveBio::CreateableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::UpdateableAPIResource

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
    puts '-' * 50
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
    so = resp.to_solvebio
    puts so.inspect
    puts so.str

    if ARGV[0]
        require_relative './cli/auth.rb'
        include SolveBio::Auth
        login
        puts '-' * 30, ' HELP ', '-' * 30
        puts SolveBio::Depository.retrieve('ClinVar').help
        puts '-' * 30, ' Retrieve ClinVar ','-' * 30
        puts SolveBio::Depository.retrieve('ClinVar').str
        puts '-' * 30, ' Versions ClinVar ','-' * 30
        puts SolveBio::Depository.retrieve('Clinvar').versions.str
        puts '-' * 30, ' Dataset  ','-' * 30
        puts SolveBio::Dataset.retrieve('Clinvar/2.0.0-1/Variants').str
        puts '-' * 30, ' All Depository  ','-' * 30
        puts SolveBio::Depository.all.str
    end
end