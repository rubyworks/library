require 'rbconfig'
require 'library'

# RubyLibrary is a specialized subclass of Library specifically designed
# to sever Ruby's standard library. It is used to speed up load times for
# for library files that are standard Ruby scripts and should never be
# overriden by any 3rd party libraries. Good examples are 'ostruct' and
# 'optparse'.
#
# This class is in the proccess of being refined to exclude certian 3rd
# party redistributions, such RDoc and Soap4r.
#
class RubyLibrary < Library

  #
  # Arch directory relative to the ruby lib dir.
  #
  #ARCHPATH = ::RbConfig::CONFIG['archdir'].sub(::RbConfig::CONFIG['rubylibdir']+'/', '')

  #
  # Arch directory relative to the site_ruby lib dir.
  #
  #ARCHPATH = ::RbConfig::CONFIG['sitearchdir'].sub(::RbConfig::CONFIG['sitelibdir']+'/', '')

  #
  # Setup new Ruby library.
  #
  def initialize #(location, name=nil, options={})
    rubylibdir  = ::RbConfig::CONFIG['rubylibdir']
    sitelibdir  = ::RbConfig::CONFIG['sitelibdir']

    rubyarchdir = ::RbConfig::CONFIG['archdir']
    sitearchdir = ::RbConfig::CONFIG['sitearchdir']

    common = find_base_path([rubylibdir, sitelibdir])

    @location = common
    @loadpath = [sitelibdir, sitearchdir, rubylibdir, rubyarchdir].map{ |d| d.sub(common+'/','') }

    @name     = 'ruby'
    @options  = {} #?
  end

  #
  # Then name of the RubyLibrary is `ruby`.
  #
  def name
    'ruby'
  end

  #
  # Ruby version.
  #
  def version
    RUBY_VERSION
  end


  # TODO: 1.9+ need to remove rugbygems ?

  #
  #
  #
  def loadpath
    @loadpath ||= ['', ARCHPATH]
    #$LOAD_PATH - ['.']
    #$LOAD_PATH - ['.']
    #[], ].compact
  end

  #
  # Release date.
  #
  # @todo This currently just returns current date/time.
  #   Is there a way to get Ruby's own release date?
  #
  def date
    Time.now
  end

  #
  alias released date

  #
  # Ruby requires nothing.
  #
  def requires
    []
  end

  #
  # Ruby needs to ignore a few 3rd party libraries. They will
  # be picked up by the final fallback to Ruby's original require
  # if all else fails.
  #
  def find(file, suffix=true)
    return nil if /^rdoc/ =~ file
    super(file, suffix)
  end

  #
  # Location of executable. This is alwasy bin/. This is a fixed
  # convention, unlike lib/ which needs to be more flexable.
  #
  def bindir
    File.join(location, 'bin')
  end

  #
  # Is there a <tt>bin/</tt> location?
  #
  def bindir?
    File.exist?(bindir)
  end

  #
  # Location of library system configuration files.
  # This is alwasy the <tt>etc/</tt> directory.
  #
  def confdir
    File.join(location, 'etc')
  end

  #
  # Is there a <tt>etc/</tt> location?
  #
  def confdir?
    File.exist?(confdir)
  end

  #
  # Location of library shared data directory.
  # This is always the <tt>data/</tt> directory.
  #
  def datadir
    File.join(location, 'data')
  end

  #
  # Is there a <tt>data/</tt> location?
  #
  def datadir?
    File.exist?(datadir)
  end

  #
  # Require library +file+ given as a Script instance.
  #
  # @param [String] feature
  #   Instance of Feature.
  #
  # @return [Boolean] Success of requiring the feature.
  #
  def require_absolute(feature)
    return false if $".include?(feature.localname)  # ruby 1.8 does not use absolutes
    success = super(feature)
    $" << feature.localname # ruby 1.8 does not use absolutes TODO: move up?
    $".uniq!
    success
  end

  #
  # Load library +file+ given as a Script instance.
  #
  # @param [String] feature
  #   Instance of Feature.
  #
  # @return [Boolean] Success of loading the feature.
  #
  def load_absolute(feature, wrap=nil)
    success = super(feature, wrap)
    $" << feature.localname # ruby 1.8 does not use absolutes TODO: move up?
    $".uniq!
    success
  end

  #
  # The loadpath sorted by largest path first.
  #
  def loadpath_sorted
    loadpath.sort{ |a,b| b.size <=> a.size }
  end

  #
  # Construct a Script match.
  #
  def libfile(lpath, file, ext=nil)
    Library::Feature.new(self, lpath, file, ext) 
  end

private

  # Given an array of path strings, find the longest common prefix path.
  def find_base_path(paths)
    return paths.first if paths.length <= 1
    arr = paths.sort
    f = arr.first.split('/')
    l = arr.last.split('/')
    i = 0
    i += 1 while f[i] == l[i] && i <= f.length
    f.slice(0, i).join('/')
  end

end







=begin
# TODO: Can we merge RubySiteLibrary with RubyLibrary? If not the maybe rename RubyLibrary to RubyCoreLibrary.
# We could unite them, but only if we set @location to whatever path rubylibdir and sitelibdir
# have in common, which might not be much, i.e. `/usr/local`

#
class RubySiteLibrary < RubyLibrary

  #
  # New library.
  #
  def initialize #(location, name=nil, options={})
    @location = ::RbConfig::CONFIG['sitelibdir']
    @name     = 'site_ruby'
    @options  = {} #?
  end

  #
  #
  #
  def name
    'site_ruby'
  end

  #
  # Ruby version.
  #
  def version
    RUBY_VERSION
  end

  #
  # Arch directory relative to the site_ruby lib dir.
  #
  ARCHPATH = ::RbConfig::CONFIG['sitearchdir'].sub(::RbConfig::CONFIG['sitelibdir']+'/', '')

  # TODO: 1.9+ need to remove rugbygems ?

  #
  #
  #
  def loadpath
    @loadpath ||= ['', ARCHPATH]
    #$LOAD_PATH - ['.']
    #$LOAD_PATH - ['.']
    #[], ].compact
  end

end
=end
