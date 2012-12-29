[Homepage](http://rubyworks.github.com/rolls) /
[Report Issue](http://github.com/rubyworks/rolls/issues)
[Source Code](http://github.com/rubyworks/rolls)
( )


# Ruby Rolls

<pre style="color:red">
                  ____
              ,dP9CGG88@b,
            ,IP""YICCG888@@b,
           dIi   ,IICGG8888@b
          dCIIiciIICCGG8888@@b
  ________GCCIIIICCCGGG8888@@@________________
          GGCCCCCCCGGG88888@@@
          GGGGCCCGGGG88888@@@@...
          Y8GGGGGG8888888@@@@P.....
           Y88888888888@@@@@P......
           `Y8888888@@@@@@@P'......
              `@@@@@@@@@P'.......
                  """"........
</pre>


Rolls is a library management system for Ruby. In fact, the name is
an anacronym which stands for *Ruby Objectified Library Ledger System*.
Sounds neat, but what does Rolls actually do?

Rolls core functionality is to take a list of file system locations, sift
through them to find conforming Ruby projects and makes them available via
Ruby's `require` and `load` methods. It does this in such a way that is
*highly customizable* and *very fast*.

Along with some supporting functionality, this bestows a variety of useful
possibilities to Ruby developers:

* Work with libraries in an object-oriented manner.
* Develop interdependent projects in real time without installs or vendoring. 
* Create isolated library environments based on project requirements.
* Nullify the need for per-project gemsets and multiple copies of the same gem.
* Access libraries anywhere; there is no special "home" path they must reside.
* Serve gem installed libraries faster than RubyGems itself.

With Rolls developers can run their programs in real time --no install phase is
required for one program to depend on another. This makes it very easy to work
on a set of interdependent projects, without vendoring. It also makes easy to
create isolated library environments. Yet Roller does so efficiently
because there need only be a single copy of any given version of a library
on disc. And libraries can be stored anywhere. There is no special place
they must all reside. You simply tell Roller where they reside. And that
includes your Gem home. Roller can serve gem installed libraries as easily
as it serves development libraries.


## Status

Rolls works fairly well. The core system has been in use for years, 
so on the whole the underlying functionality is in good working order.
However, the system is still undergoing development, in particular, work
on simplifying configuration and management, so some things are yet subject
to change.


## Limitations

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So `#autoload` calls cannot make use of Rolls.  This is not as
significant as it might seem since `#autoload` is being deprecated as
of Ruby 2.0. So it is best to discontinue it's use anyway.


## Installation

### Manual Installation (Recommended)

Manual installation is recommended for regular usage, since it
can then be loaded without going through RubyGems.

To install manually either clone the Git repository via:

    $ git clone http://github.com/rubyworks/rolls.git

Or download a copy of the project tarball or zip archive. You can
find those [here](http://github.com/rubyworks/rolls/download).
Of course, unpack the file once at hand.

    $ wget http://github.com/rubyworks/library/download/rolls.tgz
    $ tar -xvzf rolls.tgz

If you already have Ruby Setup installed on your system you can
use it to handle the install (See: http://rubyworks.github.com/setup). 

    $ cd rolls
    $ setup.rb

Otherwise, the package includes a copy of Ruby Setup script that
you can use instead.

    $ cd rolls
    $ ruby script/setup.rb

Depending on your system setup you may need to use `sudo` on this
last command in order to install to the typical `/usr/local/site_ruby`
location.

### RubyGems Installation

We *strongly* recommend installing Rolls manually because Rolls is a
peer to RubyGems. However, as a way to try Rolls out, it can be 
installed via RubyGems.

    $ gem install rolls

If you like Rolls, then later you can uninstall the rolls gem and
do a proper manual install via Setup.rb.


## Instructions

### System Setup

First add the following line to your shell startup script, e.g. your
`.bashrc` file.

    . ~/.ruby-library.sh

Then create the `~/.ruby-library.sh` script containing the following lines

    export RUBYOPT="-rlibrary $RUBYOPT"
    export PATH="$PATH:$(ruby -e'Library.setup')"

The first line ensures that Rolls is loaded everytime Ruby is executed.
If you have other entries in the RUBYOPT variable already it is best that
the `-rolls` occur before the others.

The second line ensure that that current *library ledger* is in sync with
the current contents of managed locaations. It also returns a list of `bin/`
directories for all those managed libraries. By appending this to the system's
`PATH` variable, the executables of the libraries managed by Rolls are made
available on the command line. 

Note that this `PATH` approach to executables requires that the bin files have
their executable bits turned on and have the proper header (i.e. `#!usr/bin/env ruby`).
Also keep in mind that while this approach to handling bin paths works for most
operating systems (i.e. Unix-based systems), other systems may need to use *binstubs*
instead. But this feature that has not yet been implemented because current users have
not needed it. It will be addressed in a future release.

### Library Conformity

For a library to be accessable to Rolls it must conform to the common organizational
conventions generally used by all Ruby projects. In addition it is *best* to provide
a `.index` file of `type: ruby`. A `.index` file is recommended because it make
project metadata lookup faster and more convenient. A `.gemspec` file will work as
a fallback if a `.index` file isn't found, but it can slow things down a little.
See the [Indexer](http://rubyworks.github.com/indexer) project for more information
about `.index` files.

### Library Run Modes

The library system can operate in different *run modes*. The "production"
or "locked" mode is the default. This mode will always utilize a locked list
of avaialble libraries. This means that whenever configuration changes, 
e.g. `$RUBY_LIBRARY` is modified, or when `$GEM_PATH` is in `$RUBY_LIBRARY` and
a new library has been installed via `gem install`, then the locked list must
be resynced. If you setup your system as instructed above, this can be done
by rerunning the ~/.ruby-library.sh script.

    $ . ~/.ruby-library.sh

Continually having to resync can be inconvenient is some situations, to get
around this you can set the `$RUBY_LIBRARY_MODE` variable to "live" mode.

    $ export RUBY_LIBRARY_MODE="live"

In this mode the library ledger will be reconstructed each time Ruby runs.
This mode is *much slower* than locked mode. It also does not suffice if the
`PATH` environment variable needs to be updated. In that case, you must
still resync the ledger.

### Library Locations

By default Rolls will serve up the `$GEM_PATH` locations. For most users,
that is all that is needed and this section of instruction can be skipped.

Yet Rolls is very flexible and can be configured in any number of manners
to serve up Ruby libraries. This is done by changing the locations that
libraries are found via the `$RUBY_LIBRARY` environment variable.

For example, lets say a developer wants to ensure that a current project's
vendor location is always prepended to the library lookup to ensure the use
of any modified dependencies.

    $ export RUBY_LIBRARY="./vendor:$GEM_PATH"

Now any submodules in a project's `vendor/` directory will be accessible
via `require` and `load` (when run from the root of the project, of course).
Note, this configuration only makes sense whe using *live* mode (see below).

When using a Ruby version manager, and modifying the `$RUBY_LIBRARY` 
environment variable for more general purposes, say for instance you want
to serve up a special set of Ruby projects that you simply "install" via a
git checkout, you may want to differentiate sets of libraries based on your
current Ruby. For example, with [chruby](http://github.com/postmodern/chruby),
you could do something like:

    $ export RUBY_LIBRARY="~/.ruby-gits/$RUBY_VERSION/:$GEM_PATH"

That way, when you change your current Ruby, you also change which libraries
that are available. In most cases this is not important, but if the library has
any C extensions which must be compiled, then it may be vital to make this 
differentiation.

These are just some possible examples of how an advanced developer might choose
to configure Rolls. How you choose to do so will likely vary. If you come up
with any great general practices, be sure to let us know!

### Library Isolation

Developers often need to isolate a project's libary dependencies, both to ensure
best version resolution of those dependencies, and to isolate the project from
any malformed libraries that erroneously clobber lib paths of another project 
(yes, sadly this can happen). Rolls makes this easy to handle:




### Using the API

Rolls objectifies ... which is natuarlly called the Library class.
The basics of the Library API are fairly simple. Given a location on disc
that houses a Ruby library, e.g. `projects/hello`, a new Library instance
can be created like any other object.

    mylib = Library.new('projects/hello')

With a library object in hand, we can require or load files from that library.

    mylib.require 'world'

Or look at information about the library.

    mylib.name     #=> 'hello'
    mylib.version  #=> '1.0.0'

Crating a library object via`#new` gives us a one-off object. But to persist
the library and make it available by name we can use `#add` instead.

    Library.add('projects/hello')

Or, delving down a bit deeper into the belly of system, one could simply
feed the path to the master Ledger instance.

    $LEDGER << 'projects/hello'

Both have the same exact effect. Our library will then be available via 
Library's various look-up methods. There are a few of these. One of these is
the Kernel method `#library`.

    library('hello')

Another is `#[]` class method.

    Library['hello']

There are many other useful Library methods, see the API documentation
for more details.

Now you are *ready to roll*! 


## Documentation

The above provides a brief overview of using Rolls. But there is more to
it. To get a deeper understanding of the system and how to use +roll+ to
its fullest extent visit http://rubyworks.github.org/rolls.



## FAQ

Roller was RubyForge project #1004. She's been around a while! ;)


## COPYRIGHTS

Copyright (c) 2006 Rubyworks

Roller is distributable in accordance with the **BSD-2-Clause** license.

See the LICENSE.txt file details.

