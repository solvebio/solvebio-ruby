#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'uri'
require_relative 'main'

module SolveBio::HelpableAPIResource

    attr_reader :have_launchy

    @@have_launchy = false
    begin
        @@have_launchy = require 'launchy'
    rescue LoadError
    end

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
        if @@have_launchy
            Launchy.open(url)
        else
            puts('The SolveBio Ruby client needs the "launchy" gem to ' +
                 "open help url: #{url.to_s}")
        end
    end
end

# Demo code
if __FILE__ == $0
    include SolveBio::HelpableAPIResource
    if @@have_launchy
        open_help('docs')
        sleep 1
    else
        puts "Don't have launchy"
    end
end
