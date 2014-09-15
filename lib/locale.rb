require_relative 'main'
module SolveBio::Locale

    # Used only if r18n-core is not around
    @thousands_sep  = ','
    def thousands_sep
        @thousands_sep
    end
    def thousands_sep=(value)
        @thousands_sep = value
    end

    begin
        require 'r18n-core'
        have_r18n = true
    rescue LoadError
        have_r18n = false
    end
    if have_r18n
        @locale = ENV['LANG'] || ENV['LC_NUMERIC'] || 'en_US.UTF-8'
        R18n.set(@locale)
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

class Fixnum
    include SolveBio::Locale
    def pretty_int
        SolveBio::Locale.pretty_int(self)
    end
end

if __FILE__ == $0
    puts 10000.pretty_int
end
