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

  #
  # Library ledger.
  #
  $LEDGER = Ledger.new

  #
  # When loading files, the current library doing the loading is pushed
  # on this stack, and then popped-off when it is finished.
  #
  $LOAD_STACK = []

  #
  #
  #
  $LOAD_CACHE = {}

  # Dynamic link extension.
  #DLEXT = '.' + ::RbConfig::CONFIG['DLEXT']

  # TODO: Some extensions are platform specific --only add the ones needed
  # for the current platform to SUFFIXES.

  #
  # Possible suffixes for feature files, that #require will try automatically.
  #
  SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'] #, '']

  #
  # Extensions glob, joins extensions with comma and wrap in curly brackets.
  #
  SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

  #
  # A shortcut for #instance.
  #
  # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
  #
  def self.[](name, constraint=nil)
    $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
  end

  #
  # Get an instance of a library by name, or name and version.
  # Libraries are singleton, so once loaded the same object is
  # always returned.
  #
  # @todo This method might be deprecated.
  #
  # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
  #
  def self.instance(name, constraint=nil)
    $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
  end

  #
  # Activate a library. Same as #instance but will raise and error if the
  # library is not found. This can also take a block to yield on the library.
  #
  # @param [String] name
  #   Name of library.
  #
  # @param [String] constraint
  #   Valid version constraint.
  #
  # @raise [LoadError]
  #   If library not found.
  #
  # @return [Library]
  #   The activated Library object.
  #
  def self.activate(name, constraint=nil) #:yield:
    library = $LEDGER.activate(name, constraint)
    yield(library) if block_given?
    library
  end

  #
  # Like `#new`, but adds library to library ledger.
  #
  # @todo Better name for this method?
  #
  # @return [Library] The new library.
  #
  def self.add(location)
    $LEDGER.add_location(location)

    #library = new(location)
    #$LEDGER.add_library(library)
    #library
  end

  #
  # New Library object.
  #
  # If data is given it must have `:name` and `:version`. It can
  # also have `:loadpath`, `:date`, and `:omit`.
  #
  # @param location [String]
  #   Expanded file path to library's root directory.
  #
  # @param metadata [Hash]
  #   Overriding matadata (to circumvent loading it from `.ruby` file).
  #
  def initialize(location, metadata={})
    raise TypeError, "not a directory - #{location}" unless File.directory?(location)

    @location = location
    @active   = false

    @metadata = Metadata.new(@location, metadata)

    raise "Non-conforming library (missing name) -- `#{location}'" unless name
    raise "Non-conforming library (missing version) -- `#{location}'" unless version
  end

  #
  # Activate a library.
  #
  # @return [true,false] Has the library has been activated?
  #
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

  #
  # Location of library files on disc.
  #
  def location
    @location
  end

  # TODO: If Metadata only came from .ruby file then code could 
  #       be much simplified. Or DotRuby::Spec could be used and gemspec
  #       imported if dotruby-rubygems installed.

  #
  # Access to library metadata. Metadata is gathered from
  # the `.ruby` file or a `.gemspec` file.
  #
  # @return [Metadata] metadata object
  #
  def metadata
    @metadata
  end

  #
  # Library's "unixname".
  #
  # @return [String] name of library
  #
  def name
    @name ||= metadata.name
  end

  #
  # Library's version number.
  #
  # @return [VersionNumber] version number
  #
  def version
    @version ||= metadata.version
  end

  #
  # Library's internal load path(s). This will default to `['lib']`
  # if not otherwise given.
  #
  # @return [Array] list of load paths
  #
  def load_path
    metadata.load_path
  end

  alias_method :loadpath, :load_path

  #
  # Release date.
  #
  # @return [Time] library's release date
  #
  def date
    metadata.date
  end

  #
  # Alias for +#date+.
  #
  alias_method :released, :date

  #
  # Library's requirements.
  #
  # @return [Array] list of requirements
  #
  def requirements
    metadata.requirements
  end

  #
  # Runtime requirements. Note that in gemspec terms these are called 
  # dependencies.
  #
  # @return [Array] list of runtime requirements
  #
  def runtime_requirements
    requirements.select{ |req| req.runtime? }
  end

  # TODO: Not yet using omit.

  #
  # Omit library form ledger?
  #
  # @return [Boolean] if true, omit library from ledger
  #
  def omit
    @omit
  end

  #
  # Same as `#omit`.
  #
  alias_method :omit?, :omit

  #
  # Returns a list of load paths expand to full path names.
  #
  # @return [Array<String>] list of expanded load paths
  #
  def absolute_loadpath
    loadpath.map{ |lp| ::File.join(location, lp) }
  end

  # Take runtime requirements and open them. This will help reveal any
  # version conflicts or missing dependencies.
  def verify
    runtime_requirements.each do |req|
      name, constraint = req['name'], req['version']
      Library.open(name, constraint)
    end
  end

  # Take all requirements and open it. This will help reveal any
  # version conflicts or missing dependencies.
  def verify_all
    requirements.each do |req|
      name, constraint = req['name'], req['version']
      Library.open(name, constraint)
    end
  end

  #
  # Does a library contain a relative +file+ within it's loadpath.
  # If so return the libary file object for it, otherwise +false+.
  #
  # Note that this method was designed to maximize speed.
  #
  # @param [#to_s] file
  #   The relative pathname of the file to find.
  #
  # @param [Hash] options
  #   The Hash of optional settings to adjust search behavior.
  #
  # @option options [Boolean] :suffix
  #   Automatically try standard extensions if pathname has none.
  #
  # @option options [Boolean] :legacy
  #   Do not match within library's +name+ directory, eg. `lib/foo/*`.
  #
  # @return [Feature,nil] The feature if found.
  #
  def find(pathname, options={})
    main   = options[:main]
    #legacy = options[:legacy]
    suffix = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if SUFFIXES.include?(::File.extname(pathname))
    if suffix
      loadpath.each do |lpath|
        SUFFIXES.each do |ext|
          f = ::File.join(location, lpath, pathname + ext)
          return feature(lpath, pathname, ext) if ::File.file?(f)
        end
      end #unless legacy
      legacy_loadpath.each do |lpath|
        SUFFIXES.each do |ext|
          f = ::File.join(location, lpath, pathname + ext)
          return feature(lpath, pathname, ext) if ::File.file?(f)
        end
      end unless main
    else
      loadpath.each do |lpath|
        f = ::File.join(location, lpath, pathname)
        return feature(lpath, pathname) if ::File.file?(f)
      end #unless legacy
      legacy_loadpath.each do |lpath|
        f = ::File.join(location, lpath, pathname)        
        return feature(lpath, pathname) if ::File.file?(f)
      end unless main
    end
    nil
  end

  #
  # Alias for #find.
  #
  alias_method :include?, :find

  #
  #
  #
  def legacy?
    !legacy_loadpath.empty?
  end

  #
  #
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

  #
  # Create a new Feature object from +lpath+, +pathname+ and +ext+.
  #
  def feature(lpath, pathname, ext=nil)
    Feature.new(self, lpath, pathname, ext)
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

  #
  # Inspect library instance.
  #
  def inspect
    if version
      %[#<Library #{name}/#{version} @location="#{location}">]
    else
      %[#<Library #{name} @location="#{location}">]
    end
  end

  #
  # Same as #inspect.
  #
  def to_s
    inspect
  end

  #
  # Compare by version.
  #
  def <=>(other)
    version <=> other.version
  end

  #
  # Return default feature. This is the feature that has same name as
  # the library itself.
  #
  def default
    @default ||= find(name, :main=>true)
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

  #
  # Location of executable. This is alwasy bin/. This is a fixed
  # convention, unlike lib/ which needs to be more flexable.
  #
  def bindir
    ::File.join(location, 'bin')
  end

  #
  # Is there a `bin/` location?
  #
  def bindir? 
    ::File.exist?(bindir)
  end

  #
  # Location of library system configuration files.
  # This is alwasy the `etc/` directory.
  #
  def confdir
    ::File.join(location, 'etc')
  end

  #
  # Is there a `etc/` location?
  #
  def confdir?
    ::File.exist?(confdir)
  end

  # Location of library shared data directory.
  # This is always the `data/` directory.
  def datadir
    ::File.join(location, 'data')
  end

  # Is there a `data/` location?
  def datadir?
    ::File.exist?(datadir)
  end

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

    #
    # In which library is the current file participating?
    #
    # @return [Library] The library currently loading features.
    #
    def __LIBRARY__
      $LOAD_STACK.last.library
    end

    #
    # Activate a library, same as `Library.instance` but will raise and error
    # if the library is not found. This can also take a block to yield on the
    # library.
    #
    # @param name [String]
    #   The library's name.
    #
    # @param constraint [String]
    #   A valid version constraint.
    #
    # @return [Library] The Library instance.
    #
    def library(name, constraint=nil, &block) #:yield:
      Library.activate(name, constraint, &block)
    end

    module_function :library
  end

end
