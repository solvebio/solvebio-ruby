#!/usr/bin/env rake
# -*- Ruby -*-

ROOT_DIR         = File.dirname(__FILE__)
Gemspec_filename = 'solvebio.gemspec'

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

require 'rubygems/package_task'

task :gemspec do
  gemspec.validate
end

task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build solvebio.gemspec"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv gemspec.file_name, 'pkg'
  end
end

task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --both pkg/#{gemspec.file_name}}
    # sh %{gem install --dev --both pkg/#{gemspec.file_name}}
  end
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << './lib'
  t.pattern = './test/**/test*.rb'
  t.verbose = true
end

task :test => :lib

task :check => :test
task :default => :test
