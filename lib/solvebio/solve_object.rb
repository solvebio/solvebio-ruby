# require 'json'
# require 'set'

module SolveBio
    class SolveObject
        include Enumerable

        @@permanent_attributes = Set.new([:api_key, :id])

        def initialize(id=nil)
            if id.kind_of?(Hash)
                @retrieve_options = id.dup
                @retrieve_options.delete(:id)
            else
                @retrieve_options = {}
            end

            @values = {}
            # store manually updated values for partial updates
            @unsaved_values = Set.new

            @values[:id] = id if id
        end

        # Element Reference — Retrieves the value object corresponding to the key object.
        # Note: *key* is turned into a string before access, because the underlying key type
        # is a string.
        def [](key)
            super(key.to_s)
        end

        def self.construct_from(values)
            self.new(values[:id]).refresh_from(values)
        end

        def refresh_from(values)
            values.each do |k, v|
                @values[k] = Util.to_solve_object(v)
                @unsaved_values.delete(k)
            end
        end

        def inspect
            ident_parts = [self.class]

            if self.id.kind_of?(Integer)
                ident_parts << "id=#{self.id}"
            end

            if self.full_name
                ident_parts << "full_name=#{self.full_name}"
            end

            '<%s:%x> JSON: %s' % [ident_parts.join(' '),
                                  self.object_id, self.to_json]

        end

        def to_s
            if self.respond_to?(:tabulate)
                self.tabulate(@values)
            else
                # No equivalent of Python's json sort_keys?
                JSON.pretty_generate(@values, :indent => '  ')
            end
        end

        def [](k)
            @values[k.to_sym]
        end

        def []=(k, v)
            send(:"#{k}=", v)
        end

        def keys
            @values.keys
        end

        def values
            @values.values
        end

        def to_json(*a)
            JSON.generate(@values)
        end

        def as_json(*a)
            @values.as_json(*a)
        end

        def to_hash
            @values.inject({}) do |acc, (key, value)|
                acc[key] = value.respond_to?(:to_hash) ? value.to_hash : value
                acc
            end
        end

        def each(&blk)
            @values.each(&blk)
        end

        if RUBY_VERSION < '1.9.2'
            def respond_to?(symbol)
                @values.has_key?(symbol) || super
            end
        end

        # protected
        #
        # def metaclass
        #     class << self; self; end
        # end
        #
        # def remove_accessors(keys)
        #     metaclass.instance_eval do
        #         keys.each do |k|
        #             next if @@permanent_attributes.include?(k)
        #             k_eq = :"#{k}="
        #             remove_method(k) if method_defined?(k)
        #             remove_method(k_eq) if method_defined?(k_eq)
        #         end
        #     end
        # end
        #
        # def add_accessors(keys)
        #     metaclass.instance_eval do
        #         keys.each do |k|
        #             next if @@permanent_attributes.include?(k)
        #             k_eq = :"#{k}="
        #             define_method(k) { @values[k] }
        #             define_method(k_eq) do |v|
        #                 if v == ""
        #                     raise ArgumentError.new(
        #                         "You cannot set #{k} to an empty string." +
        #                         "We interpret empty strings as nil in requests." +
        #                         "You may set #{self}.#{k} = nil to delete the property.")
        #                 end
        #                 @values[k] = v
        #                 @unsaved_values.add(k)
        #             end
        #         end
        #     end
        # end
        #
        # def method_missing(name, *args)
        #     if name.to_s.end_with?('=')
        #         attr = name.to_s[0...-1].to_sym
        #         add_accessors([attr])
        #         begin
        #             mth = method(name)
        #         rescue NameError
        #             raise NoMethodError.new("Cannot set #{attr} on this object. HINT: you can't set: #{@@permanent_attributes.to_a.join(', ')}")
        #         end
        #         return mth.call(args[0])
        #     else
        #         return @values[name] if @values.has_key?(name)
        #     end
        #
        #     super
        # end
        #
        # def respond_to_missing?(symbol, include_private = false)
        #     @values && @values.has_key?(symbol) || super
        # end
        #
    end
end
