#!/usr/bin/env rake
# -*- Ruby -*-

ROOT_DIR         = File.dirname(__FILE__)
Gemspec_filename = 'solvebio.gemspec'

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

require 'rubygems/package_task'

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build solvebio.gemspec"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv gemspec.file_name, 'pkg'
  end
end

desc "Install the gem locally"
task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.file_name}}
  end
end

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
