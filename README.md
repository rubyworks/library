# RUBY LIBARY

<pre style="color:red">

            AdP99CCGGG88888@A
           AdPP99CCGGG888888@A
          IIIPP999CCGG8888888@i
          dIi   ,IICGGG8888888@
          dCIIiciIICCGG8888888@
  ________GCCIIIICCCGGG8888888@________________
          GGCCCCCCCGGG88888888@.....
          GGGGCCCGGGG888888888@.....
          Y8GGGGGG888888888888@.....
          Y8888888888888888888@.....
          L8888888888888888888@.....

</pre>

[home](http://rubyworks.github.com/library) /
[code](http://github.com/rubyworks/library)


## DESCRIPTION

Library objectifies the idea of a Ruby library. 

Library makes it possible for developers to develop interdependent projects
in real time, without installation phase, link configurations or vendoring. 
It also makes it possible to create isolated library environments. Library 
also does so efficiently because only a single copy of any given version
of a library is needed on disc. And libraries can be stored anywhere. There
is no special place they must all reside. Just add a new location to the
library ledger and it's is available. And that includes the Gem home. Library
can serve gem installed libraries as easily as it serves development libraries.

Library servers as the foundation for the Roller gem, which provides library
set management built ontop of the Library project.


## USAGE

### Using the API

The basics of the Library API are fairly simple. Given a location on disc
that houses a Ruby library,

    mylib = Library.new('projects/hello')

Now you can require or load files form that library.

    mylib.require 'world'

Or look at information about the library.

    mylib.name     #=> 'hello'
    mylib.version  #=> '1.0.0'

The above gives you a one-off Library object. To make the library available 
by name we can use:

    Library.add(location)

or 

    $LEDGER << location

Both have the same exact effect. Our library will then be available via 
Library's various lookup methods. There are a few of these. One of these is
the Kernel method `#library`.

    library('hello')

Another is `Library[]`.

    Library['hello']

There are many other useful Library methods, see the API documentation
for more details.

### Using RUBYPATH

To use Library on a regular basis you can add the library paths you want to
to the +RUBYPATH+ environment variable.

    export RUBYPATH="~/workspace/ruby-projects"

Then add `-rubypath` to the RUBYOPT environment variable.

    export RUBYOPT="-rubypath"

You might already have `-rubygems` there, which is fine too.

    export RUBYOPT="-rubypath -rubygems"

If you want access to project executables you will also need to append the
project `bin` locations to the PATH envvironment variable.

    export PATH="$PATH:$(ruby -e'Library::PATH()')"

This will add the +bin+ locations of the programs encompassed by your
current RUBYPATH environment.

Of course, you will probably want to add these lines to your startup `.bashrc`
file (or equivalent) so they are ready to go every time you bring up your
shell console.

### Preparing your Projects

For a project to be usable via Library it must conform to common organizational
standards for a Ruby project. Most importantly it should have a `.ruby` file.
It is highly recommend that a project have a `.ruby` file although Library can
fallback to `.gemspec` if a `.ruby` file isn't found. But relying on a `.gemspec`
of going to slow things down. Library can also handle installed gems. If you
point Library torwards a gem home, it will gather the necessary metadata from
the relative `specifications/*.gemspec` though again an available `.ruby` file
in the project is going to improve performance.

See http://dotruby.github.com/dotruby for more information about `.ruby` files.

### Autoload Caveat

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So `#autoload` calls cannot mkae use of the Library setup. 
This is not as signifficant as it might seem since `#autoload` is being
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

Ruby Library is distributable in accordance with the *FreeBSD* license.

See the COPYING.rdoc file details.

