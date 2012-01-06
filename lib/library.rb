require 'library/core_ext'
require 'library/ledger'
require 'library/load_error'
require 'library/metadata'
require 'library/feature'
require 'library/version'
require 'library/domain'

# Library class encapsulates a location on disc that contains a Ruby
# project, with loadable features, of course.
#
class Library

  # Library ledger.
  $LEDGER = Ledger.new

  # When loading files, the current library doing the loading is pushed
  # on this stack, and then popped-off when it is finished.
  $LOAD_STACK = []

  #
  $LOAD_CACHE = {}

  # Dynamic link extension.
  #DLEXT = '.' + ::RbConfig::CONFIG['DLEXT']

  # TODO: Some extensions are platform specific --only
  # add the ones needed for the current platform.
  SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'] #, '']

  # Extensions glob, joins extensions with comma and wrap in curly brackets.
  SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

  # New Library object.
  #
  # If data is given it must have `:name` and `:version`. It can
  # also have `:loadpath`, `:date`, and `:omit`.
  #
  # @param location [String]
  #   expanded file path to library's root directory
  #
  # @param data [Hash]
  #   priming matadata (to circumvent loading it from `.ruby` file)
  #
  def initialize(location, free=false) #, data={})
    @location = location
    @active   = false

    #data = (data.rekey)

    #if data.empty?
    #  load_metadata
    #else
    #  @name     = data[:name]
    #  @version  = Version.new(data[:version])
    #  @loadpath = data[:loadpath]
    #  @date     = data[:date]  # TODO: convert to Time
    #  @omit     = data[:omit]
    #end

    @metadata = Metadata.new(@location) #, :name=>name)

    raise "Non-conforming library (missing name) -- `#{location}'" unless name
    raise "Non-conforming library (missing version) -- `#{location}'" unless version

    ## if not free and another version is not already active add to ledger
    if not free
      entry = $LEDGER[name]
      if Array === entry
        entry << self unless entry.include?(self)
      end
    end
  end

  # Activate a library by putting it's loadpaths on the master $LOAD_PATH.
  # This is neccessary only for the fact that autoload will not utilize
  # customized require methods.
  #
  # @return [true] that the library has been activated
  def activate
    return if @active
    vers = $LEDGER[name]
    if Library === vers
      raise VersionConflict.new(self, vers) if vers != self
    else
      ## NOTE: we are only doing this for the sake of autoload
      ## which does not honor a customized require method.
      #if Library.autoload_hack?
      #  absolute_loadpath.each do |path|
      #    $LOAD_PATH.unshift(path)
      #  end
      #end
      $LEDGER[name] = self
    end
    # TODO: activate runtime dependencies
    #verify
    @active = true
  end

=begin
  # Constrain a library to a single version. This means, if anyone tries
  # to use a different version once a library has been constrained, an
  # VersionConflict error will be raised.
  def constrain
    cmp = $LEDGER[name]
    if Array === cmp
      $LEDGER[name] = self
    else
      if self.version != cmp.version
        raise VersionError
      end
    end
  end
=end

  # Location of library files on disc.
  def location
    @location
  end

  # TODO: If Metadata only came from .ruby file then code could 
  #       be much simplified. Or DotRuby::Spec could be used and gemspec
  #       imported if dotruby-rubygems installed.

  # Access to library metadata. Metadata is gathered from
  # the `.ruby` file or a `.gemspec` file.
  #
  # @return [Metadata] metadata object
  def metadata
    @metadata
  end

  # Library's "unixname".
  #
  # @return [String] name of library
  def name
    @name ||= metadata.name
  end

  # Library's version number.
  #
  # @return [VersionNumber] version number
  def version
    @version ||= metadata.version
  end

  # Library's internal load path(s). This will default to `['lib']`
  # if not otherwise given.
  #
  # @return [Array] list of load paths
  def loadpath
    metadata.load_path
  end

  # Release date.
  #
  # @return [Time] library's release date
  def date
    metadata.date
  end

  # Alias for +#date+.
  alias_method :released, :date

  # Library's requirements.
  #
  # @return [Array] list of requirements
  def requirements
    metadata.requirements
  end

  # Runtime requirements. Note that in gemspec terms these are called 
  # dependencies.
  #
  # @return [Array] list of runtime requirements
  def runtime_requirements
    requirements.select{ |req| req.runtime? }
  end

  # Omit library form ledger?
  #
  # @return [Boolean] if ture, omit library from ledger
  def omit
    @omit
  end

  # Same as `#omit`.
  alias_method :omit?, :omit

  # Returns a list of load paths expand to full path names.
  #
  # @return [Array<String>] list of expanded load paths
  def absolute_loadpath
    loadpath.map{ |lp| ::File.join(location, lp) }
  end

# FIXME: dealing with requirements

  # Take runtime requirements and open them. This will help reveal any
  # version conflicts or missing dependencies.
  def verify
    requirements.each do |(name, constraint)|
      Library.open(name, constraint)
    end
  end

  # Take all requirements and open it. This will help reveal any
  # version conflicts or missing dependencies.
  def verify_all
    requirements.each do |(name, constraint)|
      Library.open(name, constraint)
    end
  end

  # Does a library contain a relative +file+ within it's loadpath.
  # If so return the libary file object for it, otherwise +false+.
  #
  # file    - file path to find [to_s]
  # options - Hash of optional settings to adjust search behavior
  # options[:suffix] - automatically try standard extensions if file has none.
  # options[:legacy] - do not match within +name+ directory, eg. `lib/foo/*`.
  #
  # NOTE: This method was designed to maximize speed.
  def find(file, options={})
    main   = options[:main]
    #legacy = options[:legacy]
    suffix = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if SUFFIXES.include?(::File.extname(file))
    if suffix
      loadpath.each do |lpath|
        SUFFIXES.each do |ext|
          f = ::File.join(location, lpath, file + ext)
          return feature(lpath, file, ext) if ::File.file?(f)
        end
      end #unless legacy
      legacy_loadpath.each do |lpath|
        SUFFIXES.each do |ext|
          f = ::File.join(location, lpath, file + ext)
          return feature(lpath, file, ext) if ::File.file?(f)
        end
      end unless main
    else
      loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)
        return feature(lpath, file) if ::File.file?(f)
      end #unless legacy
      legacy_loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)        
        return feature(lpath, file) if ::File.file?(f)
      end unless main
    end
    nil
  end

  # Alias for #find.
  alias_method :include?, :find

  #
  def legacy?
    !legacy_loadpath.empty?
  end

  #
  def legacy_loadpath
    @legacy_loadpath ||= (
      path = []
      loadpath.each do |lp|
        llp = File.join(lp, name)
        dir = File.join(location, llp)
        path << llp if File.directory?(dir)
      end
      path
    )
  end

  # Create a new Script object from +lpath+, +file+ and +ext+.
  def feature(lpath, file, ext=nil)
    Script.new(self, lpath, file, ext)
  end

  #
  # Requre feature from library.
  #
  def require(pathname, options={})
    if feature = find(pathname, options)
      feature.require(options)
    else
      # TODO: silently?
      raise LoadError.new(path, name)
    end
  end

  #
  # Load feature form library.
  #
  def load(pathname, options={})
    #options[:load] = true
    if feature = find(pathname, options)
      feature.load(options)
    else
      raise LoadError.new(pathname, self.name)
    end
  end

#  #
#  def isolate(options={})
#    if options[:all]
#      list = Library.environments
#    else
#      list = [Library.environment]
#    end
#
#    results = library.requirements.verify
#
#    fails, libs = results.partition{ |r| Array === r }
#  end

  # Inspect library instance.
  def inspect
    if version
      %[#<Library #{name}/#{version} @location="#{location}">]
    else
      %[#<Library #{name} @location="#{location}">]
    end
  end

  # Same as #inspect.
  def to_s
    inspect
  end

  # Compare by version.
  def <=>(other)
    version <=> other.version
  end

  # Return default file. This is the file that has same name as the
  # library itself.
  def default
    @default ||= include?(name, :main=>true)
  end

  #--
  #    # List of subdirectories that are searched when loading.
  #    #--
  #    # This defualts to ['lib/{name}', 'lib']. The first entry is
  #    # usually proper location; the latter is added for default
  #    # compatability with the traditional require system.
  #    #++
  #    def libdir
  #      loadpath.map{ |path| ::File.join(location, path) }
  #    end
  #
  #    # Does the library have any lib directories?
  #    def libdir?
  #      lib.any?{ |d| ::File.directory?(d) }
  #    end
  #++

  # Location of executable. This is alwasy bin/. This is a fixed
  # convention, unlike lib/ which needs to be more flexable.
  def bindir  ; ::File.join(location, 'bin') ; end

  # Is there a <tt>bin/</tt> location?
  def bindir? ; ::File.exist?(bindir) ; end

  # Location of library system configuration files.
  # This is alwasy the <tt>etc/</tt> directory.
  def confdir ; ::File.join(location, 'etc') ; end

  # Is there a <tt>etc/</tt> location?
  def confdir? ; ::File.exist?(confdir) ; end

  # Location of library shared data directory.
  # This is always the <tt>data/</tt> directory.
  def datadir ; ::File.join(location, 'data') ; end

  # Is there a <tt>data/</tt> location?
  def datadir? ; ::File.exist?(datadir) ; end

  #
  #def to_rb
  #  to_h.inspect
  #end

  #
  # Convert to hash.
  #
  # @return [Hash] The library metadata in a hash.
  #
  def to_h
    {
      :location     => location,
      :name         => name,
      :version      => version.to_s,
      :loadpath     => loadpath,
      :date         => date,
      :requirements => requirements
    }
  end

  module ::Kernel
    class << self
      alias __require__ require
      alias __load__    load
    end

    alias __require__ require
    alias __load__    load

    # In which library is the current file participating?
    #
    # @return [Library] currently loading Library instance
    def __LIBRARY__
      $LOAD_STACK.last
    end

    # Activate a library.
    # Same as #library_instance but will raise and error if the library is
    # not found. This can also take a block to yield on the library.
    #
    # @param name [String]
    #   the library's name
    #
    # @param constraint [String]
    #   a valid version constraint
    #
    # @return [Library] the Library instance
    def library(name, constraint=nil, &block) #:yield:
      Library.activate(name, constraint, &block)
    end

    module_function :library
  end

end
