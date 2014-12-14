#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module IRB
    module_function
    def shell
        # Set to run the standard trepan IRB profile
        irbrc = File.
            expand_path(File.join(File.dirname(__FILE__), 'irbrc.rb'))

        # Start out with our custom profile
        old_irbrc = ENV['IRBRC']
        ENV['IRBRC'] = irbrc
        IRB.setup(nil)

        # If the user has an IRB profile or SolveBio IRB profile, run
        # that now.
        ENV['IRBRC'] = ENV['SOLVEBIO_IRBRC'] || old_irbrc
        if ENV['IRBRC']
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
