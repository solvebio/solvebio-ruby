# -*- ruby -*-
# irbrc profile for SolveBio
IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:PROMPT][:SIMPLE] = {
  :PROMPT_C => '[SolveBio] In ?: ',  # Prompt when continuing a statement
  :PROMPT_I => '[SolveBio] In  : ',  # Normal prompt
  :PROMPT_N => '[SolveBio] In +: ',  # Prompt when indenting code
  :PROMPT_S => '[SolveBio] In %l: ', # Prompt when continuing a string
  :RETURN   => "[SolveBio] Out : %s\n"
 }

require 'solvebio'
require 'solvebio/cli'

have_completion = nil
begin
    require 'bond' and require 'bond/completion'
    have_completion = 'bond'
rescue LoadError
    begin
        have_completion = require 'irb/completion'
    rescue LoadError
        have_completion = false
    end
end

unless have_completion
    if have_completion != 'bond'
        puts "Please install the 'bond' getm for better autocompletion"
    end
end

# If an API key is set in SolveBio.api_key, use that.
# Otherwise, look for credentials in the local file,
# Otherwise, ask the user to log in.

if SolveBio.api_key or SolveBio::CLI::Credentials.get_credentials
    email, SolveBio.api_key = SolveBio::CLI::Auth::whoami
else
    SolveBio::CLI::Auth.login
end

if not SolveBio.api_key
    puts("SolveBio requires a valid account. To sign up, visit: https://www.solvebio.com/signup")
    exit 1
end

include SolveBio
