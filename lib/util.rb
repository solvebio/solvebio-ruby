module SolveBio

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
