module SolveBio
    module CLI
        module Auth
            include SolveBio::CLI::Credentials

            module_function
            def print_message(msg)
                if SolveBio.api_host != 'https://api.solvebio.com'
                    msg += " (#{SolveBio.api_host})"
                end
                puts msg + '.'
            end

            def ask_for_credentials()
                print_message('Enter your SolveBio credentials')
                domain = Readline.readline('Domain (e.g. <domain>.solvebio.com): ', true)
                email = Readline.readline('Email: ', true)
                print 'Password (typing will be hidden): '
                password = STDIN.noecho(&:gets).chomp
                puts
                return domain, email, password
            end

            def send_install_report
                require 'rbconfig';
                data = {
                    :client                => 'ruby',
                    :client_version        => SolveBio::VERSION,
                    :ruby_version          => RbConfig::CONFIG['RUBY_PROGRAM_VERSION'],
                    :ruby_implementation   => RbConfig::CONFIG['RUBY_SO_NAME'],
                    :architecture          => RbConfig::CONFIG['arch'],
                }
                Client.post('/v1/reports/install', data) rescue nil
            end

            def login
                domain, email, password = ask_for_credentials
        
                if not domain or not email or not password
                    puts "Domain, email, and password are all required."
                    return false
                end
                    
                data = {
                    :domain   => domain.gsub('.solvebio.com', ''),
                    :email    => email,
                    :password => password
                }

                begin
                    response = Client.post('/v1/auth/token', data)
                rescue SolveBio::SolveError => e
                    puts "Login failed: #{e.to_s}"
                    return false
                end

                delete_credentials
                save_credentials(email.downcase, response[:token])
                SolveBio.api_key = response[:token]
                send_install_report
                print_message("You are now logged-in as #{email}")
                return true
            end

            def logout
                if get_credentials
                    delete_credentials
                    print_message('You have been logged out')
                    return true
                end

                print_message('You are not logged-in')
                return false
            end

            def whoami
                email = nil
                api_key = SolveBio.api_key
                
                # Override local credentials with existing key
                if SolveBio.api_key
                    begin
                        user = Client.get('/v1/user')
                        email = user[:email]
                    rescue SolveBio::SolveError => e
                        SolveBio.api_key = nil
                        api_key = nil
                        print_message("Error: #{e.to_s}")
                    end
                else
                    begin
                        email, api_key = get_credentials
                    rescue
                        nil
                    end
                end

                if not email.nil?
                    print_message("You are logged-in as #{email}")
                else
                    print_message("You are not logged-in")
                end

                return email, api_key
            end
        end
    end
end
