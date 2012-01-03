---
source:
- var
authors:
- name: trans
  email: transfire@gmail.com
copyrights:
- holder: Rubyworks
  year: '2006'
  license: BSD-2-Clause
replacements: []
alternatives: []
requirements:
- name: detroit
  groups:
  - build
  development: true
- name: setup
  version: 5.0+
  groups:
  - build
  development: true
- name: qed
  version: 2.2.2+
  groups:
  - test
  development: true
dependencies: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/library.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/library
  code: http://github.com/rubyworks/library
  mail: http://groups.google.com/groups/rubyworks-mailinglist
extra: {}
load_path:
- lib
revision: 0
created: '2006-12-10'
summary: Objectifying the Ruby Library
title: Library
version: 1.0.0
name: library
description: ! "The Library class encapsulates the essential nature \nof a Ruby library
  --a location on disk from which\nscripts can be required."
organization: rubyworks
date: '2012-01-03'
