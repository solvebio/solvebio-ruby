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
require_relative '../resource/apiresource'
include SolveBio

puts <<-INTRO
You are in a SolveBio Interactive Ruby (irb) session.
INTRO

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

login_if_needed
