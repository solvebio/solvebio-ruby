module SolveBio
    module CLI
        module Auth
            def ask_for_credentials(email=nil)
                while true
                    email ||= Readline.readline('Email address: ', true)
                    print 'Password (typing will be hidden): '
                    password = STDIN.noecho(&:gets).chomp
                    puts
                    # FIXME: validate email address?
                    if email and password
                        return email, password
                    else
                        # FIXME: could say which one is needed.
                        print 'Email and password are both required.'
                        return nil, nil
                    end
                end
            end

            module_function

            def send_install_report
                require 'rbconfig';
                data = {
                    :client                => 'ruby',
                    :client_version        => SolveBio::VERSION,
                    :ruby_version          => RbConfig::CONFIG['RUBY_PROGRAM_VERSION'],
                    :ruby_implementation   => RbConfig::CONFIG['RUBY_SO_NAME'],
                    :architecture          => RbConfig::CONFIG['arch'],
                }
                Client.request('post', '/v1/reports/install', {:payload => data}) rescue nil
            end

            def login_msg(email)
                msg = "\nYou are logged in as %s" % email
                if SolveBio::api_host != 'https://api.solvebio.com'
                    msg += ' on %s' % SolveBio::api_host
                end
                puts msg
            end

            # Prompt user for login information (email/password).
            # Email and password are used to get the user's auth_token key.
            def login(email=nil, api_key=nil)
                if api_key
                    old_api_key = SolveBio.api_key
                    begin
                        SolveBio.api_key = api_key
                        response = SolveBio::Client.get('/v1/user', {})
                    rescue SolveError => e
                        puts 'Login failed: %s' % e.message
                        SolveBio.api_key = old_api_key
                        return false
                    end
                    email = response['email']
                    save_credentials email, api_key
                    send_install_report
                    login_msg(email)
                    return true
                else
                    email, password = ask_for_credentials email
                    data = {
                        :email    => email,
                        :password => password
                    }

                    begin
                        response = SolveBio::Client.client
                            .request 'post', '/v1/auth/token', {:payload => data}
                    rescue SolveBio::Error => e
                        puts "Login failed: #{e.to_s}"
                        return false
                    else
                        save_credentials(email.downcase, response['token'])
                        # reset the default client's auth token
                        SolveBio.api_key = response['token']
                        send_install_report
                        puts 'You are now logged-in.'
                        return true
                    end
                end
            end

            # If the credentials file has our api host key use that. Otherwise,
            # ask for credentials.
            def login_if_needed
                creds = get_credentials
                if creds
                    SolveBio.api_key = creds[1]
                    login_msg()
                    return true
                else
                    return login(nil, SolveBio.api_key)
                end
            end

            def logout
                if get_credentials
                    delete_credentials
                    SolveBio.api_key = nil
                    puts 'You have been logged out.'
                    return true
                else
                    puts 'You are not logged-in.'
                    return false
                end
            end

            def whoami
                creds = get_credentials
                if creds
                    puts creds[0]
                    return creds[0]
                else
                    puts 'You are not logged-in.'
                    return nil
                end
            end

        end
    end
end
