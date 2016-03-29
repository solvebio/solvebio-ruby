[![Build Status](https://travis-ci.org/solvebio/solvebio-ruby.svg?branch=master)](http://travis-ci.org/solvebio/solvebio-ruby)


SolveBio Ruby Client
====================

This is the SolveBio Ruby module and command-line interface (CLI).

For more information about SolveBio, see [solvebio.com](https://www.solvebio.com).


Guided Installation
-------------------

To use the guided installer, open up your terminal and paste this:

    curl -skL install.solvebio.com/ruby | bash


Manual Installation
-------------------

    sudo gem install solvebio


Installing from Git
-------------------

First, install dependencies:
	
    gem install rest-client addressable netrc

Install from source:

    git clone https://github.com/solvebio/solvebio-ruby.git
	cd solvebio-ruby
    rake test
    sudo rake install


This will install the `solvebio` gem and the `solvebio.rb` CLI.


Optional Dependencies
---------------------

The following optional gems can make your shell experience better

* [bond](http://tagaholic.me/bond/)

    Better command completion

* [launchy](https://github.com/copiousfreetime/launchy)

    Opens help URLs in a web browser tab

* [rb18n-core](https://https://github.com/ai/r18n)

    Localization for number formatting


Documentation
-------------

See the [SolveBio API Reference](https://docs.solvebio.com/) for more information about using the API.
