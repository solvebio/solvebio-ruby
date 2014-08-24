#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Open the SolveBio shell, an IRB wrapper
require 'irb'

module IRB

    # Stuff to add IRB commands goes here
    module ExtendCommand
    end

    module_function

    def shell

        # Set to run the standard trepan IRB profile
        irbrc = File.
            expand_path(File.join(File.dirname(__FILE__), 'irbrc.rb'))

        ENV['IRBRC'] = irbrc
        IRB.setup(nil)

        # If the user has a IRB profile, run that now.
        if ENV['SOLVEBIO_IRB']
            ENV['IRBRC'] = ENV['SOLVEBIO_IRB']
            @CONF[:RC_NAME_GENERATOR]=nil
            IRB.run_config
        end

        @CONF[:AUTO_INDENT] = true
        workspace = IRB::WorkSpace.new
        irb = IRB::Irb.new(workspace)

        @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
        @CONF[:MAIN_CONTEXT] = irb.context

        catch(:IRB_EXIT) do
            irb.eval_input
        end
    end
end

# Demo it.
if __FILE__ == $0
    IRB::shell
end
