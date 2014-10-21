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

require_relative '../solvebio'
require_relative '../solvebio/resource'
include SolveBio::Auth

# Set some demo names that can be used.
SAMPLE_DEPO         = 'ClinVar'
SAMPLE_DEPO_VERSION = "#{SAMPLE_DEPO}/2.0.0-1"
SAMPLE_DATASET      = "#{SAMPLE_DEPO_VERSION}/Variants"

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
'irb/completion'
'bond' 'bond/completion'

puts <<-INTRO
You are in a SolveBio Interactive Ruby (irb) session...
Type SolveBio::help for help on SolveBio.
INTRO

unless have_completion
    if have_completion != 'bond'
        puts "You might get better completion using the 'bond' gem"
    end
end

# Report whether we are logged in.
include SolveBio::Credentials
creds = get_credentials()
if creds
    puts "You are logged in as #{creds[0]}"
else
    puts 'You are not logged in yet. Login using "login [email [, password]]"'

end
