class Library
  
  # This module simply extends the Library class, giving it certain
  # convenience methods for interacting with the current Ledger.
  #
  # TODO: Change name of module, or move to Library.
  #
  module Ledgered

    require 'tmpdir'

    #
    # Access to library ledger.
    #
    # @return [Array] The `$LEDGER` array.
    #
    def ledger
      $LEDGER
    end

    #
    # Library names from ledger.
    #
    # @return [Array] The keys from `$LEDGER` array.
    #
    def names
      $LEDGER.keys
    end

    alias_method :list, :names

    #
    # A shortcut for #instance.
    #
    # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
    #
    def [](name, constraint=nil)
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
    def instance(name, constraint=nil)
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
    def activate(name, constraint=nil, &block) #:yield:
      $LEDGER.activate(name, constraint, &block)
    end

    #
    # Like `#new`, but adds library to library ledger.
    #
    # @todo Better name for this method?
    #
    # @return [Library] The new library.
    #
    def add(location)
      $LEDGER.add(location)
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find(path, options={})
      $LEDGER.find_feature(path, options)
    end

    #
    # Brute force variation of `#find` looks through all libraries for a 
    # matching features. This serves as the fallback method if `#find` comes
    # up empty.
    #
    # @param [String] path
    #   path name for which to search
    #
    # @param [Hash] options
    #   Search options.
    #
    # @option options [Boolean] :latest
    #   Search only the active or most current version of any library.
    #
    # @option options [Boolean] :suffix
    #   Automatically try standard extensions if pathname has none.
    #
    # @option options [Boolean] :legacy
    #   Do not match within library's +name+ directory, eg. `lib/foo/*`.
    #
    # @return [Feature,Array] Matching feature(s).
    #
    def find_any(path, options={})
      $LEDGER.find_any(path, options)
    end

    #
    # Brute force search looks through all libraries for matching features.
    # This is the same as #find_any, but returns a list of matches rather
    # then the first matching feature found.
    #
    # @param [String] path
    #   path name for which to search
    #
    # @param [Hash] options
    #   Search options.
    #
    # @option options [Boolean] :latest
    #   Search only the active or most current version of any library.
    #
    # @option options [Boolean] :suffix
    #   Automatically try standard extensions if pathname has none.
    #
    # @option options [Boolean] :legacy
    #   Do not match within library's +name+ directory, eg. `lib/foo/*`.
    #
    # @return [Feature,Array] Matching feature(s).
    #
    def search(path, options={})
      $LEDGER.search(path, options)
    end

    #
    # Search for all matching library files that match the given pattern.
    # This could be of useful for plugin loader.
    #
    # @param [Hash] options
    #   Glob matching options.
    #
    # @option options [Boolean] :latest
    #   Search only activated libraries or the most recent version
    #   of a given library.
    #
    # @return [Array] Matching file paths.
    #
    # @todo Should this return list of Feature objects instead of file paths?
    #
    def glob(match, options={})
      $LEDGER.glob(match, options)
    end

    #
    # @deprecated
    #
    def find_files(match, options={})
      glob(match, options)
    end

    #
    # Access to global load stack.
    # When loading files, the current library doing the loading is pushed
    # on this stack, and then popped-off when it is finished.
    #
    # @return [Array] The `$LOAD_STACK` array.
    #
    def load_stack
      $LOAD_STACK
    end

    #
    # Require a feature from the library.
    #
    # @param [String] pathname
    #   The pathname of feature relative to library's loadpath.
    #
    # @param [Hash] options
    #
    # @return [true,false] If feature was newly required or successfully loaded.
    #
    def require(pathname, options={})
      $LEDGER.require(pathname, options)
    end

    #
    # Load file path. This is just like #require except that previously
    # loaded files will be reloaded and standard extensions will not be
    # automatically appended.
    #
    # @param pathname [String]
    #   pathname of feature relative to library's loadpath
    #
    # @return [true,false] if feature was successfully loaded
    #
    def load(pathname, options={}) #, &block)
      $LEDGER.load(pathname, options)
    end

    #
    # Like require but also with local lookup. It will first check to see
    # if the currently loading library has the path relative to its load paths.
    #
    #   acquire('core_ext/margin')
    #
    # To "load" the library, rather than "require" it, set the +:load+
    # option to true.
    #
    #   acquire('core_ext/string/margin', :load=>true)
    #
    # @param pathname [String]
    #   Pathname of feature relative to library's loadpath.
    #
    # @return [true, false] If feature was newly required.
    #
    def acquire(pathname, options={}) #, &block)
      $LEDGER.acquire(pathname, options)
    end


    #
    # Go thru each library and collect bin paths.
    #
    # @todo Should this be defined on Ledger?
    #
    def PATH()
      path = []
      list.each do |name|
        lib = Library[name]   # TODO: This activates each library, probably not what we want, get max version instead?
        path << lib.bindir if lib.bindir?
      end
      path.join(windows_platform? ? ';' : ':')
    end

    #
    #
    #
    def lock
      output = lock_file

      dir = File.dirname(output)
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      File.open(output, 'w+') do |f|
        f << $LEDGER.to_yaml
      end
    end

    #
    # Remove lock file and reset ledger.
    #
    def unlock
      FileUtils.rm(lock_file) if File.exist?(lock_file)
      reset!
    end

    #
    #
    #
    def sync
      unlock if locked?
      lock
      PATH()
    end

    #
    # Library lock file.
    #
    def lock_file
      File.join(tmpdir, "#{ruby_version}.ledger")
    end

    #
    #
    #
    def live?
      ENV['RUBY_LIBRARY_MODE'] == 'live'
    end

    #
    #
    #
    def locked?
      File.exist?(lock_file)
    end

    #
    #
    #
    def reset!
      #$LEDGER = Ledger.new
      #$LOAD_STACK = []
      #$LOAD_CACHE = {}

      if File.exist?(lock_file) && ! live?
        ledger = YAML.load_file(lock_file)
        case ledger
        when Ledger
          $LEDGER = ledger
          return $LEDGER
        when Hash
          $LEDGER.replace(ledger)
          return $LEDGER
        else
          warn "Bad cached ledger at #{lock_file}"
        end
      end

      $LEDGER.prime(*path_list, :expound=>true)
    end

  private

    #
    # TODO: Better definition of `RbConfig#windows_platform?`.
    #
    def windows_platform?
      case RUBY_PLATFORM
      when /mswin/, /wince/
        true
      else
        false
      end
    end

    #
    #
    #
    def bootstrap!
      reset!
      require_relative 'kernel'
    end

    #
    #
    #
    def tmpdir
      File.join(Dir.tmpdir, 'ruby')
    end

    #
    #
    #
    def ruby_version
      if ruby = ENV['RUBY']
        File.basename(ruby)
      else
        RUBY_VERSION
      end
    end

    #
    # Library list file.
    #
    #def path_file
    #  File.expand_path("~/.ruby/#{ruby_version}.path")
    #  #File.expand_path('~/.ruby-path')
    #end

    #
    # TODO: Should the path file take precedence over the environment variable?
    #
    def path_list
      if list = ENV['RUBY_LIBRARY']
        list.split(/[:;]/)
      #elsif File.exist?(path_file)
      #  File.readlines(path_file).map{ |x| x.strip }.reject{ |x| x.empty? || x =~ /^\s*\#/ }
      elsif ENV['GEM_PATH']
        ENV['GEM_PATH'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
      elsif ENV['GEM_HOME']
        ENV['GEM_HOME'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
      else
        warn "No Ruby libraries."
        []
      end
    end

  end

  extend Ledgered
end
