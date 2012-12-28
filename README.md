[Homepage](http://rubyworks.github.com/rolls) /
[Source Code](http://github.com/rubyworks/rolls)


# RUBY ROLLER

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


## DESCRIPTION

Roller is a library manager for Ruby. With Roller developers can run their
programs in real time --no install phase is required for one program
to depend on another. This makes it very easy to work on a set of
interdependent projects, without vendoring. It also makes easy to
create isolated library environments. Yet Roller does so efficiently
because there need only be a single copy of any given version of a library
on disc. And libraries can be stored anywhere. There is no special place
they must all reside. You simply tell Roller where they reside. And that
includes your Gem home. Roller can serve gem installed libraries as easily
as it serves development libraries.


Library is, as its name implies, the objectification of the Ruby library.
Along with the Library Ledger, which keeps an indexed list of available
libraries, a variety of useful features are bestowed to Ruby developers.

* Work with libraries in an object-oriented manner.
* Develop interdependent projects in real time without installing, linking or vendoring. 
* Create isolated library environments based on project requirements.
* Libraries can be stored anywhere. There is no special "home" path they must reside.
* Serve gem installed libraries as easily as it serves developer's libraries.
* Is the foundation of the Rolls gem, which provides a superset of library management functions.

IMPORTANT: Presently gem installed packages can only be served if a `.ruby` file
is part of the gem package. This should be fixed in the next release. To work
around the `dotruby` gem can be used to generate a `.ruby` file for installed
gems.






## STATUS

Roller works fairly well. I have used it for development for years, so
on the whole it stays in working order. However it is still under
development, so configuration is still subject to a fair bit of change.
The loading heuristics are quite advanced, which accounts for the speed,
but as a trade-off the loading procedure is more complex.


## INSTRUCTION

### Setting Up

To use roll regularly you first need to add it your RUBYOPT environment
variable.

    $ export RUBYOPT="-roll"

If you want to use RubyGems as a fallback, this can be done too:

    $ export RUBYOPT="-roll -rubygems"

The alternative to this is to add your gem locations to your roll
environment (see below).

To support executables you will also need to add a line to your startup
.bashrc (or equivalent) file.

    export PATH="$PATH:$(roll path)"

This will add the +bin+ locations of the programs encompassed by your
current roll environment.

(NOTE: The way bin paths are handled might change to a symlink directory
in the future if limitations of long environment variables prove problematic.
So far I have not had any issues with the PATH approach.)

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

### Using RUBYLIBS

To use Library on a regular basis, add library paths to the `RUBYLIBS`
environment variable. (NOTICE It is plural!!!)

    export RUBYLIBS="~/workspace/ruby-projects"

And add `-rubylibs` to the RUBYOPT environment variable.

    export RUBYOPT="-rubylibs"

You might already have `-rubygems` there, which is fine too.

    export RUBYOPT="-rubylibs -rubygems"

If you want access to project executables you will also need to append the
project `bin` locations to the PATH environment variable.

    export PATH="$PATH:$(ruby -e'Library::PATH()')"

This will add the `bin` locations of the programs encompassed by your
current `RUBYLIBS` setting.

Of course, you will probably want to add these lines to your startup `.bashrc`
file (or equivalent) so they are ready to go every time you bring up your
shell console.

### Preping Projects

For a project to be usable via Library it must conform to common organizational
conventions for a Ruby project and it should have a `.ruby` file.

It is highly recommend that a project have a `.ruby` file although a `.gemspec`
file can serve as a fallback if a `.ruby` file isn't found. But relying on a
`.gemspec` is going to slow things down a fair bit. It also requires that
the `dotruby` library be installed.

To activate .gemspec support set the environment variable `RUBYLIBS_GEMSPEC=true`.

See http://dotruby.github.com/dotruby for more information about `.ruby` files.

### Preparing Projects

For a project to be detected by Roller it must conform to a
minimal POM[http://proutils.github.com/pom] setup. Specifically,
the project must have <code>.meta/</code> file with `type: ruby`.
That is the bare minimum for a project to be loadable via Roller.
The only exception is for installed gems. If you point Roller torwards
a gem home, Roller will gather the necessary metadata from the gem's
.gemspec file instead.

See Meta[http://wiki.github.com/rubyworks/meta] for more information about
the <code>.meta/</code> file.

### Library Management

Next you need to setup an roll *environment*. The default environment
is called +production+. You can add a library search location to it
using +roll in+. Eg.

    $ roll in /opt/ruby/

As a developer you will may want to setup a +development+ environment.
To change or add an environment use the +use+ command.

    $ roll use development

Then you can add the paths you want. For instance my development
environment is essentially constructed like this:

    $ roll in ~/programs/proutils
    $ roll in ~/programs/rubyworks
    $ roll in ~/programs/trans

By default these paths will be searched for POM conforming projects
up to a depth of three sub-directories. That's suitable for
most needs. You can specify the the depth explicitly with the 
<tt>--depth</tt> or <tt>-d</tt> option. You can roll in the 
current working directory by leaving off the path argument. 
If the current directory has a +.ruby+ directory, a depth of +1+
will automatically be used.

In the same way you can add gem locations to you roll environment.
For instance on my system:

    $ sudo roll in /usr/lib/ruby/gems/1.8/gems

Note the use of +sudo+ here. Roller will create <code>.ruby/</coide>
entries automatically in each gem if not already present. Since these
are system-wide gems +sudo+ is needed to give rolls write access.
This is only necessary the first time any new gem is rolled in.

If a rolled in location changes --say you start a new project, or
install a new gem, you can resync you roll index via the +sync+ command.

    $ roll sync

Resyncing is only needed when a new project is added to an enironments
lookup locations, or if one of the already included projects change
the `name` or `load_path` in the `.meta` file. To clarify, take a look at the
+show+ command.

    $ roll show --index

The +use+ command stores the current environment name until the
end of the bash session. To set it perminently, adjust the RUBYENV
environment variable or write the fallback default in the 
<code>$HOME/.config/roll/default</code> file.

For see the rest of the +roll+ commands, use <code>roll help</code>.

Now you are *read to roll*! 

### Autoload Caveat

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So `#autoload` calls cannot make use of Rolls.  This is not as
significant as it might seem since `#autoload` is being deprecated as
of Ruby 2.0. So it is best to discontinue it's use anyway.


## LEARNING MORE

The above provides a brief overview of using Rolls. But there is more to
it. To get a deeper understanding of the system and how to use +roll+ to
its fullest extent visit http://rubyworks.github.org/rolls.


## INSTALLATION

### RubyGems Installation

We strongly recommend installing Rolls manually because Rolls is
a peer to RubyGems. However, the last we tested it, Rolls can
be install via RubyGems as a means of trying it out, though you
will not get the full benefits of the system.

    $ gem install rolls

If you like Rolls, then later you can uninstall the gem and
do a proper manual install via Setup.rb.


### Manual Installation (Recommended)

Manual installation is recommended for regular usage, since it
can then be loaded without going through RubyGems.

First you need a copy of the tarball (or zip) archive. You will
find them [here](http://github.com/rubyworks/library/download).
You will the need to unpack the file. For example,

    $ tar -xvzf rolls-2.0.0

If you already have Ruby Setup installed on your system you can
use it to install (See: http://rubyworks.github.com/setup). 

    $ cd rolls-2.0.0
    $ setup.rb

Otherwise, the package includes a copy of Ruby Setup that you can
use.

    $ cd rolls-2.0.0
    $ script/setup.

On Windows, this last line will need to be 'ruby script/setup'.


## BY THE WAY

Roller was RubyForge project #1004. She's been around a while! ;)


## COPYRIGHTS

Copyright (c) 2006 Rubyworks

Roller is distributable in accordance with the **BSD-2-Clause** license.

See the LICENSE.txt file details.

