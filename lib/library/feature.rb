class Library

  # The Feature class represents a single file within a library.
  #
  # This class had been called `Script` until it occured to me that
  # Ruby choose the name "feature" by it's use of tem in the global
  # variable `$LOADED_FEATURES`.
  #
  class Feature

    #
    # Create a new Feature instance.
    #
    # @param library [Library]
    #   The Library object to which the feature belongs.
    #
    # @param loadpath [String]
    #   The loadpath within the library in which the feature resides.
    #
    # @param filename [String]
    #   The file path of the feature relative to the loadpath.
    #
    # @param extension [Boolean]
    #   File extension to append to the feature filename.
    #
    def initialize(library, loadpath, filename, extension=nil)
      @library   = library
      @loadpath  = loadpath
      @filename  = filename
      @extension = extension
    end

    #
    # The Library object to which the file belongs.
    #
    attr_reader :library

    #
    # The loadpath within the library in which the feature resides.
    #
    attr_reader :loadpath

    #
    # The file path of the feature relative to the loadpath.
    #
    attr_reader :filename

    #
    #
    #
    attr_reader :extension

    #
    # Name of the library to which the feature belongs.
    #
    # @return [String] name of the feature's library
    #
    def library_name
      Library===library ? library.name : nil
    end

    #
    #
    #
    def library_activate
      library.activate if Library===library
    end

    #
    # Library location.
    #
    # @return [Sting] location of library
    #
    def location
      Library===library ? library.location : library
    end

    #
    # Full path name of of feature.
    #
    # @return [String] expanded file path of feature 
    #
    def fullname
      @fullname ||= ::File.join(location, loadpath, filename + (extension || ''))
    end

    #
    # The path of the feature relative to the loadpath.
    #
    # @return [String] file path less location and loadpath
    #
    def localname
      @localname ||= ::File.join(filename + (extension || ''))
    end

    #
    # Acquire the feature --Roll's advanced require/load method.
    #
    # @return [true,false] true if loaded, false if it already has been loaded.
    #
    def acquire(options={})
      if options[:load] # TODO: .delete(:load) ?
        load(options)
      else
        require(options)
      end
    end

    #
    # Require feature.
    #
    # @return [true,false] true if loaded, false if it already has been loaded.
    #
    def require(options={})
      if library_name == 'ruby' or library_name == 'site_ruby'
        return false if $".include?(localname)  # ruby 1.8 does not use absolutes
        $" << localname # ruby 1.8 does not use absolutes
      end

      Library.load_stack << self #library
      begin
        library_activate unless options[:force]
        success = __require__(fullname)
      #rescue ::LoadError => load_error  # TODO: deativeate this if $DEBUG ?
      #  raise LoadError.new(localname, library_name)
      ensure
        Library.load_stack.pop
      end
      success
    end

    #
    # Load feature.
    #
    # @return [true,false] true if loaded, false if it already has been loaded.
    #
    def load(options={})
      if library_name == 'ruby' or library_name == 'site_ruby'
        $" << localname # ruby 1.8 does not use absolutes
      end

      Library.load_stack << self #library
      begin
        library_activate unless options[:force]
        success = __load__(fullname, options[:wrap])
      #rescue ::LoadError => load_error
      #  raise LoadError.new(localname, library_name)
      ensure
        Library.load_stack.pop
      end
      success
    end

    #
    # Compare this features full path name to another using `#==`.
    #
    # @param [Feature,String] another feature or file path.
    #
    # @return [true,false] do the features represent the the same file
    #
    def ==(other)
      fullname == other.to_s
    end

    #
    # Same as `#==`.
    #
    # @param [Feature, String] another feature or file path.
    #
    # @return [true, false] if features are the same file
    #
    def eql?(other)
      fullname == other.to_s
    end

    #
    # Same a fullname.
    #
    # @return [String] expanded file path
    #
    def to_s
      fullname
    end

    #
    # Same a fullname.
    #
    # @return [String] expanded file path
    #
    def to_str
      fullname
    end

    #
    # Use `#fullname` to calculate a hash value for the feature file.
    #
    # @return [Integer] hash value
    #
    def hash
      fullname.hash
    end

  end

end
