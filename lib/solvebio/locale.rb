module SolveBio
    module Locale
        # Used only if r18n-core is not around
        @thousands_sep  = ','
        @locale = ENV['LANG'] || ENV['LC_NUMERIC'] || 'en_US.UTF-8'
        def thousands_sep
            @thousands_sep
        end
        def thousands_sep=(value)
            @thousands_sep = value
        end

        begin
            old_verbose = $VERBOSE
            $VERBOSE = false
            require 'r18n-core'
            R18n.set(@locale)
            $VERBOSE = old_verbose
            have_r18n = true
        rescue LoadError
            have_r18n = false
        end
        if have_r18n
            def pretty_int(num)
                R18n::l(num)
            end
        else
            def pretty_int(num)
                num.to_s.reverse.scan(/\d{1,3}/).join(@thousands_sep).reverse
            end
        end

        module_function :pretty_int
    end
end

class Fixnum
    include SolveBio::Locale

    def pretty_int
        SolveBio::Locale.pretty_int(self)
    end
end
