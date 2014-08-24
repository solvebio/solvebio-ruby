#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'uri'
require_relative 'main'

# try:
#     import webbrowser
# except ImportError:
#     webbrowser = None

module SolveBio::HelpableAPIResource

    def self.included base
        base.send :include, InstanceMethods
    end

    module InstanceMethods
        def help
            open_help(self['full_name'])
        end
    end

    def open_help(path)
        url = URI::join('https://www.solvebio.com/', path)
        # begin:
        #     webbrowser.open(url)
        # rescue webbrowser.Error:
        puts('The SolveBio Ruby client was unable to open the following ' +
             'URL: %s' % url.to_s)
    end
end

# Demo code
if __FILE__ == $0
    include SolveBio::HelpableAPIResource
    open_help('')
    open_help('docs')
end
