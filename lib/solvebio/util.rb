module SolveBio
    module Util
        def self.object_classes
          @object_classes ||= {
            'Depository'        => Depository,
            'DepositoryVersion' => DepositoryVersion,
            'Dataset'           => Dataset,
            'DatasetField'      => DatasetField,
            'Sample'            => Sample,
            'Annotation'        => Annotation,
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
                object_classes.fetch(resp['class_name'], SolveObject).construct_from(resp)
            else
                resp
            end
        end

        module_function
        def pluralize(name)
               if name.end_with?('y')
                   name = name[0..-2] + 'ie'
               end
            return name + "s"
        end

        # Add underscore before internal uppercase letters. Also, lowercase
        # all letters.
        def camelcase_to_underscore(name)
            # Using [[:upper:]] and [[:lower]] should help with Unicode.
            s1 = name.gsub(/(.)([[:upper:]])([[:lower:]]+)/){"#{$1}_#{$2}#{$3}"}
            return (s1.gsub(/([a-z0-9])([[:upper:]])/){"#{$1}_#{$2}"}).downcase
        end
    end
end
