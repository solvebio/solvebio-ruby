[![Build Status](https://travis-ci.org/rocky/solvebio-ruby.svg)](https://travis-ci.org/rocky/solvebio-ruby)

# SolveBio Ruby Client


This packages provides a command-line interface (CLI) and Ruby API interface to SolveBio.

For more information about SolveBio see http://www.solvebio.com

# Installation

Right now we only support installing from git:

    git clone https://github.com/rocky/solvebio-ruby.git
	cd solvebio-ruby
	rake test          # or make test
    sudo rake install  # or make install

This also builds a *solvebio* gem which you can use elsewhere.

But note, you can also run right inside the git repository without installing anything. For example, running:

    git clone https://github.com/rocky/solvebio-ruby.git
	solvebio-ruby/bin/solvebio.rb

will get you into a solvebio irb shell. Just about any Ruby file in the project can be run standalone, and when done so, it demos that Ruby code.

# Demo code and Documentation

See the [demo folder](https://github.com/rocky/solvebio-ruby/tree/master/demo) for ready-to-run examples.

The [SolveBio Python API documentation](https://www.solvebio.com/docs/api/?python) has examples. Change Python's `import solvebio`, to Ruby's `require 'solvebio'`.  And anywhere you see `solvebio.`, change that to `SolveBio::`. For example, Python's:

    solvebio.Depository.retrieve("ClinVar").versions()

becomes Ruby's:

    BioSolve::Depository.retrieve("ClinVar").versions()

As with any other Ruby method call, you can drop the final parenthesis if you like.

# To Do

The query module, which includes filters hasn't been done yet. Lots of more tests and demo programs should be written.
