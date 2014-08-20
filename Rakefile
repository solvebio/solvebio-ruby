#!/usr/bin/env rake
# -*- Ruby -*-
require 'rake/testtask'
desc "Test everything."
Rake::TestTask.new(:test) do |t|
  t.libs << './lib'
  t.test_files = FileList['test/test-*.rb']
  t.verbose = true
end
task :test => :lib

desc "same as test"
task :check => :test
task :default => :test
