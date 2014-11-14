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
        super(key.to_s)
    end

    def self.construct_from(cls, values)
        instance = cls.new(values['id'])
        instance.refresh_from(values)
        instance
    end

    def refresh_from(values)
        self.clear()
        @unsaved_values = Set.new
        values.each { |k, v| self[k] = to_solve_object(v) }
    end

    def request(method, url, params={})
        response = SolveBio::Client.client
            .request method, url, {:params => params}
        to_solve_object(response)
    end

    def inspect
        ident_parts = [self.class]

        if self['id'].kind_of?(Integer)
            ident_parts << "id=#{self['id']}"
        end

        if allow_full_name_id and self['full_name']
            ident_parts << "full_name=#{self['full_name']}"
        end

        '<%s:%x> JSON: %s' % [ident_parts.join(' '),
                              self.object_id, self.to_json]

    end

    def to_s
        if self.respond_to?(:tabulate)
            self.tabulate(self)
        else
            # No equivalent of Python's json sort_keys?
            JSON.pretty_generate(self, :indent => '  ')
        end
    end

    # @property
    def id
        self['id']
    end
end

class Hash
    def to_solvebio(klass=nil)
        resp = self.dup()
        if ! klass
            klass_name ||= resp['class_name']
            if klass_name.kind_of?(String)
                klass = SolveBio::SolveObject::CONVERSION[klass_name] ||
                        SolveBio::SolveObject
            else
                klass = SolveBio::SolveObject
            end
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
    if resp.kind_of?(Array) or
            (not resp.kind_of? SolveBio::SolveObject and resp.kind_of?(Hash))
        resp.to_solvebio
    else
        return resp
    end
end

if __FILE__ == $0
    puts SolveBio::SolveObject.new.inspect
    puts SolveBio::SolveObject.new(64).inspect

end
