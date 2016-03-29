module SolveBio
    module Util
        def self.object_classes
          @object_classes ||= {
            'Depository'        => Depository,
            'DepositoryVersion' => DepositoryVersion,
            'Dataset'           => Dataset,
            'DatasetField'      => DatasetField,
            'User'              => User,
            'Account'           => Account,
            'list'              => ListObject
          }
        end

        def self.to_solve_object(resp)
            case resp
            when Array
                resp.map { |i| to_solve_object(i) }
            when Hash
                object_classes.fetch(resp[:class_name], SolveObject).construct_from(resp)
            else
                resp
            end
        end
        
        def self.symbolize_names(object)
            case object
            when Hash
                new_hash = {}
                object.each do |key, value|
                    key = (key.to_sym rescue key) || key
                    new_hash[key] = symbolize_names(value)
                end
                new_hash
            when Array
                object.map { |value| symbolize_names(value) }
            else
                object
            end
        end

        module_function
        def pluralize(name)
               if name.end_with?('y')
                   name = name[0..-2] + 'ie'
               end
            return name + "s"
        end

        def camelcase_to_underscore(name)
            # Add underscore before internal uppercase letters.
            # Using [[:upper:]] and [[:lower]] should help with Unicode.
            s1 = name.gsub(/(.)([[:upper:]])([[:lower:]]+)/){"#{$1}_#{$2}#{$3}"}
            return (s1.gsub(/([a-z0-9])([[:upper:]])/){"#{$1}_#{$2}"}).downcase
        end
    end
end
