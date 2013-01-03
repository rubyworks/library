class Library

  # The Feature class represents a single file within a library.
  #
  # This class had been called `Script` until it occured to me that
  # Ruby choose the name "feature" by it's use of them in the global
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

      @required = {}
    end

    #
    # The Library object to which the file belongs.
    #
    attr_reader :library

    #
    # The loadpath within the library in which the feature resides.
    #
    # @return [Array] Load path relative to library location.
    #
    attr_reader :loadpath

    #
    # The file path of the feature relative to the loadpath.
    #
    attr_reader :filename

    #
    # Extension of feature file, e.g. `.rb`.
    #
    attr_reader :extension

    #
    # Name of the library to which the feature belongs.
    #
    # @return [String] name of the feature's library
    #
    def library_name
      Library === library ? library.name : nil
    end

    #
    #
    #
    def library_activate
      if Library === library
        library.activate
        #Library.activate(library)
      end
    end

    #
    # Library location.
    #
    # @return [String] location of library
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
    # Load feature.
    #
    # @param [Hash] options
    #
    # @option options [Boolean] :require
    #   Load the feature only once (per scope).
    #
    # @return [true,false] true if loaded/required, false otherwise.
    #
    def load(options={})
      # ruby 1.8 does not use absolutes
      #if library_name == 'ruby' #or library_name == 'site_ruby'
      #  if options[:require] && !options[:wrap]
      #    return false if $".include?(localname)
      #    $" << localname
      #  end
      #end

      $LOAD_STACK << self #library
      begin
        library_activate unless options[:force]
        success = evaluate(options[:wrap], options[:require])
      #rescue ::LoadError => load_error
      #  raise LoadError.new(localname, library_name)
      ensure
        $LOAD_STACK.pop
      end
      success
    end

    #
    # Require feature. This is the same as load except the the feature will
    # only be loaded once per scope. The default scope is `TOPLEVEL_BINDING`.
    #
    # @return [true,false] true if loaded, false if it already has been loaded.
    #
    def require(options={})
      options[:require] = true
      load(options)
    end

    #def require(options={})
    #  if library_name == 'ruby' #or library_name == 'site_ruby'
    #    return false if $".include?(localname)  # ruby 1.8 does not use absolutes
    #    $" << localname                         # ruby 1.8 does not use absolutes
    #  end
    #
    #  # TODO: return false if $".include(fullname) ? But Ruby should be handling this.
    #
    #  Library.load_stack << self #library
    #  begin
    #    library_activate unless options[:force]
    #    @required = true
    #    success = require_without_library(fullname)
    #  #rescue ::LoadError => load_error  # TODO: deativeate this if $DEBUG ?
    #  #  raise LoadError.new(localname, library_name)
    #  ensure
    #    Library.load_stack.pop
    #  end
    #  success
    #end

    #
    # Has the feature been required?
    #
    def required?(scope=nil)
      @required[scope || TOPLEVEL_BINDING]
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

    #
    # Read file.
    #
    def read
      ::File.read(fullname)
    end

  private

    #
    # Evaluate feature within given scope.
    #
    # @param [Boolean] required
    #   Only evaluate once per scope.
    #
    # @return [Boolean] Will return true if evaluated, false otherwise.
    #
    def evaluate(scope, required=false)
      return false if required && required?(scope)

      case scope
      when FalseClass, NilClass, TrueClass
        if required
          success = require_without_library(fullname)
          @required[TOPLEVEL_BINDING] = true if required
        else
          success = load_without_library(fullname, scope)
        end
      when Module, Class
        scope.module_eval(read, fullname)
        @required[scope] = true if required
        success = true
      when Binding
        scope.eval(read, fullname)
        @required[scope] = true if required
        success = true
      else
        # TODO: Evaluate feature into object scope ?
        raise LoadError
      end

      success
    end

  end

end
