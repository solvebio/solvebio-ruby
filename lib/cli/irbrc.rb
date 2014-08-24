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

require_relative '../solvebio-api'
require_relative 'auth'
include SolveBio::Auth

SAMPLE_DEPO         = 'ClinVar'
SAMPLE_DEPO_VERSION = "#{SAMPLE_DEPO}/2.0.0-1"
SAMPLE_DATASET      = "#{SAMPLE_DEPO_VERSION}/Variants"

puts 'You are in a SolveBio Interactive Ruby (irb) session...'
