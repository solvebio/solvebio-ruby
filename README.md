[![Build Status](https://travis-ci.org/rocky/solvebio-ruby.svg)](https://travis-ci.org/rocky/solvebio-ruby)

# SolveBio Ruby Client


The solve Python package and command-line interface (CLI) are used to work in our bioinformatics environment.

For more information about SolveBio see http://www.solvebio.com

# Installation

Right now we only support installing from git:

    git clone https://github.com/rocky/solvebio-ruby.git
	cd solvebio-ruby
	rake test          # or make test
    sudo rake install  # or make install

In the process this builds a *solvebio* gem which you can use elsewhere.

But note, you can also run right inside the git repository without installing anything. For example:

    git clone https://github.com/rocky/solvebio-ruby.git
	solvebio-ruby/bin/solvebio.rb

will get you into a solvebio irb shell. Just about any file in the project can be run standalone demos that Ruby file.

# Demo code and Documentation

See the folder demo for ready-to-run examples.

The [biosolve Python API documentation](https://www.solvebio.com/docs/api/?python) has examples. Change Python's `import solvebio`, to Ruby's `require 'solvebio'`.  And anywhere you see `biosolve.`, change that to `BioSolve::`. For example:

    solvebio.Depository.retrieve("ClinVar").versions()

becomes:

    BioSolve::Depository.retrieve("ClinVar").versions()

As with any other Ruby method call, you can drop the final parenthesis if you like.
