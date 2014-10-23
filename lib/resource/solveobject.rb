# -*- coding: utf-8 -*-

require 'json'
require 'set'
require_relative '../client'

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

    # Element Reference — Retrieves the value object corresponding to the key object.
    # Note: *key* is turned into a string before access, because the underlying key type
    # is a string.
    def [](key)
        return super(key.to_s)
    end

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

    def request(method, url, params={})
        response = SolveBio::Client.client
            .request method, url, {:params => params}
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

    def to_s
        # No equivalent of Python's json sort_keys?
        return JSON.pretty_generate(self, :indent => '  ')
        # return self.to_json json.dumps(self, sort_keys=true, indent=2)
    end

    # @property
    def id
        return self['id']
    end
end

if __FILE__ == $0
    %w(abc abcDef abc01Def aBcDef a1B2C3 ?Foo Dataset).each do |word|
        puts word + " -> " + camelcase_to_underscore(word)
    end
    puts SolveBio::SolveObject.new.inspect
    puts SolveBio::SolveObject.new(64).inspect

end
