## -*- Ruby -*-
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'solvebio/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  # s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  # s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'solvebio'
  s.version           = SolveBio::VERSION

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Ruby bindings for the SolveBio API"
  s.description = <<-EOD
SolveBio is a platform for biomedical datasets. With SolveBio you can
forget about parsing complex flat files and sifting through cryptic
datasets. Just use the Ruby Client and API to explore massive
datasets and automate just about any bioinformatics workflow.

See https://www.solvebio.com/ for more information.
EOD

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ['SolveBio']
  s.email    = 'contact@solvebio.com'
  s.homepage = 'https://www.solvebio.com'
  s.license = 'MIT'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0")

  ## If your gem includes any executables, list them here.
  s.executables = ['solvebio.rb']
  s.default_executable = 'solvebio.rb'

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[LICENSE]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.

  s.add_dependency('netrc', '~> 0.7')
  s.add_dependency('rest-client', '~> 1.7', '>= 1.7.3')
  s.add_dependency('addressable', '~> 2.3', '>= 2.3.6')

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('webmock')
  s.files = `git ls-files`.split($/)

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.grep(/^test/)
end
