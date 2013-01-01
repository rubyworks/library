# Library class encapsulates a location on disc that contains a Ruby
# project, with loadable features, of course.
#
class Library
  require 'rolls/library/load_error'
  require 'rolls/library/validation_error'
  require 'rolls/library/ledgered'
  require 'rolls/library/metadata'
  require 'rolls/library/feature'

  extend Ledgered

  #
  # Dynamic link extension.
  #
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
  # New Library object.
  #
  # If data is given it must have `:name` and `:version`. It can
  # also have `:loadpath`, `:date`, and `:omit`.
  #
  # @param location [String]
  #   Expanded file path to library's root directory.
  #
  # @param metadata [Hash]
  #   Overriding matadata (to circumvent loading it from `.index` file).
  #
  def initialize(location, metadata={})
    raise TypeError, "not a directory - #{location}" unless File.directory?(location)

    @location = location
    @metadata = Metadata.new(location, metadata)

    raise ValidationError, "Non-conforming library (missing name) -- `#{location}'" unless name
    raise ValidationError, "Non-conforming library (missing version) -- `#{location}'" unless version
  end

  # TODO: All instance method calling on $LEDGER should probably be moved the Ledger class
  #       and called there. Looks like that would be #activate, #verify and #active? methods.

  #
  # Activate a library.
  #
  # @return [true,false] Has the library has been activated?
  #
  def activate
    current = $LEDGER[name]

    if Library === current
      raise VersionConflict.new(self, current) if current != self
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

    # TODO: activate runtime requirements?
    #verify
  end

  #
  # Take requirements and activate them. This will reveal any
  # version conflicts or missing dependencies.
  #
  # @param [Boolean] development
  #   Include development dependencies?
  #
  def verify(development=false)
    reqs = development ? requirements : runtime_requirements
    reqs.each do |req|
      name, constraint = req['name'], req['version']
      Library.activate(name, constraint)
    end
  end

  #
  # Is this library active in global ledger?
  #
  def active?
    $LEDGER[name] == self
  end


  #
  # Location of library files on disc.
  #
  def location
    @location
  end

  #
  # Access to library metadata. Metadata is gathered from
  # the `.index` file or a `.gemspec` file.
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
  # Library's requirements. Note that in gemspec terminology these are
  # called *dependencies*.
  #
  # @return [Array] list of requirements
  #
  def requirements
    metadata.requirements
  end

  #
  # Runtime requirements.
  #
  # @return [Array] list of runtime requirements
  #
  def runtime_requirements
    requirements.select{ |req| !req['development'] }
  end

  #
  # Omit library form ledger?
  #
  # @return [Boolean] if true, omit library from ledger
  #
  def omit
    @metadata.omit
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
  #   (deprecated) Do not match within library's +name+ directory, eg. `lib/foo/*`.
  #
  # @return [Feature,nil] The feature, if found.
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
  # What is `legacy_loadpath`? Well, library doesn't require you to put your
  # library's scripts in a named lib path, e.g. `lib/foo/`. Instead one can
  # just put them in `lib/` b/c Library keeps things indexed by honest to
  # goodness library names. The `legacy_path` then is used to handle these
  # old style paths along with the new.
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
      raise LoadError.new(path, name)  # TODO: silently?
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
      :date         => date.to_s,
      :requirements => requirements
    }
  end

  module ::Kernel
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
