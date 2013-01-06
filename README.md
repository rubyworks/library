[Homepage](http://rubyworks.github.com/library) /
[Documentation](http://wiki.github.com/rubyworks/library) /
[Report Issue](http://github.com/rubyworks/library/issues) /
[Source Code](http://github.com/rubyworks/library)
( [![Build Status](https://travis-ci.org/rubyworks/autoload.png)](https://travis-ci.org/rubyworks/library) )


# [The Ruby Library<br/> &nbsp; &nbsp; as a Library](#description)

*Library* is library management system for Ruby. More specifically, it is a
reformulation and partial-reimplementation of Ruby's load system. At it's 
core, the `Library` class is the objectification of a location in the file
system from which Ruby scripts can be required. It is accompanied by a 
`Library::Ledger` which tracks a set such locations, and makes them available
via Ruby's standard `require` and `load` methods. Unlike Ruby's built-in load
system, Library supports versioning and it does all this in a way that is both
easily *customizable* and *fast*.

Combined with some supporting functionality, this bestows a variety of useful
possibilities to Ruby developers:

* Work with libraries in an object-oriented manner.
* Develop interdependent projects in real time without installs or vendoring. 
* Create isolated library environments based on project requirements.
* Nullify the need for per-project gemsets and multiple copies of the same gem.
* Access libraries anywhere; there is no special "home" path they *must* reside.
* Can also serve gem installed libraries as easily as any others.


## Documentation

Because there is fair amount of information to cover this section will
refer you to the project wiki pages for instruction. Most users can follow
the [Quick Start Guide](https://github.com/rubyworks/library/wiki/Quick-Start-Guide).
For more detailed instruction on how setup Library and get the most out select
from the following links:

* [Installation](https://github.com/rubyworks/library/wiki/Installation)
* [System Setup](https://github.com/rubyworks/library/wiki/System-Setup)
* [Project Conformity](https://github.com/rubyworks/library/wiki/Project-Conformity)
* [Run Modes](https://github.com/rubyworks/library/wiki/Run-Modes)
* [Dependency Isolation](https://github.com/rubyworks/library/wiki/Dependency-Isolation)
* [Configuring Locations](https://github.com/library/wiki/Configuring-Locations)
* [API Usage](https://github.com/rubyworks/library/wiki/API-Usage)


## Status

Library started out as a project called "ROLL", which stood for *Ruby Objectified Library Ledger*.
Create in 2006, it was RubyForge project #1004. She's actually been around a while!
Over the years the code has gone through several rewrites, but has always remained in service
as a development tool. So, on the whole, the underlying functionality is in good working order.
However, the system is still undergoing some refinement --as one can imagine, it is not the 
easiest type of library to write or maintain. So some things are still subject to change.


## Copyrights

Library is copyrighted open source software.

    Copyright (c) 2006 Rubyworks. All rights reserved.

It can be modified and redistributable in accordance with the **BSD-2-Clause** license.

See the LICENSE.txt file details.

