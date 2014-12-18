module SolveBio
    module CLI
        module Tutorial
            def tutorial
                tutorial_file = File.join(File.dirname(__FILE__), "tutorial.md")
                less = which('less') 
                if less
                    exec less + ' ' + tutorial_file
                else
                    puts File.read(tutorial_file)
                    puts
                    puts "#######################################################################"
                    puts
                    puts "Warning: 'less' command not found in $PATH."
                    puts "Read the tutorial online at https://www.solvebio.com/docs/ruby-tutorial"
                    puts
                    puts "#######################################################################"
                    puts
                end
            end
            module_function :tutorial

            def which(cmd)
                exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
                ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
                    exts.each { |ext|
                        exe = File.join(path, "#{cmd}#{ext}")
                        return exe if File.executable?(exe) && !File.directory?(exe)
                    }
                end
                return nil
            end
        end
    end
end
