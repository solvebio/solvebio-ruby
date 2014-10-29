# -*- coding: utf-8 -*-

require_relative 'solveobject'
require_relative 'annotation'
require_relative 'apiresource'
require_relative 'dataset'
require_relative 'datasetfield'
require_relative 'depository'
require_relative 'depositoryversion'
require_relative 'sample'
require_relative 'user'

class SolveBio::ListObject < SolveBio::SolveObject

    include Enumerable

    def all(params={})
        return request('get', self['url'], {:params => params})
    end

    def create(params={})
        return request('post', self['url'], {:params => params})
    end

    def next_page(params={})
        if self['links']['next']
            return request('get', self['links']['next'], {:params => params})
        end
        return nil
    end

    def prev_page(params={})
        if self['links']['prev']
            request('get', self['links']['prev'], {:params => params})
        end
        return nil
    end

    def at(i)
        self.to_a[i]
    end

    def to_a
        return to_solve_object(self['data'])
    end

    def each(*pass)
        return self unless block_given?
        i = 0
        ary = self.dup
        done = false
        until done
            if i >= ary['data'].size
                ary = next_page
                break unless ary
                i = 0
            end
            yield(ary.at(i))
            i += 1
        end
        return self
    end

    def first
        self['data'][0]
    end

    # def max
    #     self['data'][self['total']]
    # end

end


SolveBio::SolveObject::CONVERSION = {
    'Annotation'        => SolveBio::Annotation,
    'Depository'        => SolveBio::Depository,
    'DepositoryVersion' => SolveBio::DepositoryVersion,
    'Dataset'           => SolveBio::Dataset,
    'DatasetField'      => SolveBio::DatasetField,
    'Sample'            => SolveBio::Sample,
    'User'              => SolveBio::User,
    'list'              => SolveBio::ListObject
}

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
    puts so.to_s

    if ARGV[0]
        require_relative './cli/auth.rb'
        include SolveBio::Auth
        login
        puts '-' * 30, ' HELP ', '-' * 30
        puts SolveBio::Depository.retrieve('ClinVar').help
        puts '-' * 30, ' Retrieve ClinVar ','-' * 30
        puts SolveBio::Depository.retrieve('ClinVar').to_s
        puts '-' * 30, ' Versions ClinVar ','-' * 30
        puts SolveBio::Depository.retrieve('Clinvar').versions.to_s
        puts '-' * 30, ' Dataset  ','-' * 30
        puts SolveBio::Dataset.retrieve('Clinvar/2.0.0-1/Variants').to_s
        puts '-' * 30, ' All Depository  ','-' * 30
        puts SolveBio::Depository.all.to_s
    end
end
