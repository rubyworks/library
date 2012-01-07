# RUBY LIBRARY

<img src="" />

[home](http://rubyworks.github.com/library) /
[code](http://github.com/rubyworks/library)


## DESCRIPTION

Library is, as its name implies, the objectification of the Ruby library.
Along with the Library Ledger, which keeps an indexed list of available
libraries, a variety of useful features are bestowed to Ruby developers.

* Work with libraries in an object-oriented manner.
* Develop interdependent projects in real time without installing, linking or vendoring. 
* Create isolated library environments based on project requirements.
* Libraries can be stored anywhere. There is no special "home" path they must reside.
* Serve gem installed libraries as easily as it serves developer's libraries.
* Is the foundation of the Rolls gem, which provides a superset of library management functions.


## USAGE

### Using the API

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

### Using RUBYENV

To use Library on a regular basis, add library paths to the `RUBYPATH`
environment variable.

    export RUBYENV="~/workspace/ruby-projects"

And add `-rubyenv` to the RUBYOPT environment variable.

    export RUBYOPT="-rubyenv"

You might already have `-rubygems` there, which is fine too.

    export RUBYOPT="-rubyenv -rubygems"

If you want access to project executables you will also need to append the
project `bin` locations to the PATH environment variable.

    export PATH="$PATH:$(ruby -e'Library::PATH()')"

This will add the `bin` locations of the programs encompassed by your
current `RUBYENV` setting.

Of course, you will probably want to add these lines to your startup `.bashrc`
file (or equivalent) so they are ready to go every time you bring up your
shell console.

### Preping Projects

For a project to be usable via Library it must conform to common organizational
conventions for a Ruby project. Most importantly it should have a `.ruby` file.
It is highly recommend that a project have a `.ruby` file although Library can
fallback to `.gemspec` if a `.ruby` file isn't found. But relying on a `.gemspec`
of going to slow things down a bit.

See http://dotruby.github.com/dotruby for more information about `.ruby` files.

### Autoload Caveat

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So `#autoload` calls cannot make use of the Library setup. 
This is not as significant as it might seem since `#autoload` is being
deprecated as of Ruby 2.0. So it is best to discontinue it's use anyway.


## LEARNING MORE

The above provides a brief overview of using the Library gem. But there is
more to it. To get a deeper understanding of the system its fullest extent,
please visit http://rubyworks.github.org/library.


## INSTALLATION

### RubyGems Installation

We strongly recommend installing Roller manually b/c Roller is a
peer to RubyGems. However, the last we tested it, Roller could
be install via Gems as a means of trying it out --though you won't
get the full benefits of the system.

    $ gem install library

If you like Roller, then later you can uninstall the gem and
do a proper manual install.


### Manual Installation

Manual installation is recommended for regular usage, since it
can then be loaded without going through RubyGems.

First you need a copy of the tarball (or zip) archive. You will
find them [here](http://github.com/rubyworks/library/download).
You will of course need to unpack the file. For example,

    $ tar -xvzf library-0.1.0

If you already have Ruby Setup installed on your system you can
use it to install (See: http://rubyworks.github.com/setup). 

    $ cd library-0.1.0
    $ sudo setup.rb

Otherwise, the package includes a copy of Ruby Setup that you can
use.

    $ cd library-0.1.0
    $ sudo script/setup.

On Windows, this last line will need to be 'ruby script/setup'.


## COPYRIGHTS

Ruby Library

Copyright (c) 2006 Rubyworks

Ruby Library is distributable in accordance with the **FreeBSD** license.

See the COPYING.rdoc file details.

