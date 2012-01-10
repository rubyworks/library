class Library

  # This extension encapsulates Library's class methods.
  #
  module Domain

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
      if file = $LOAD_CACHE[pathname]
        if options[:load]
          return file.load
        else
          return false
        end
      end

      if feature = Library.find(pathname, options)
        #file.library_activate
        $LOAD_CACHE[pathname] = feature
        return feature.acquire(options)
      end

      # fallback to Ruby's own load mechinisms
      if options[:load]
        __load__(pathname, options[:wrap])
      else
        __require__(pathname)
      end
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
      #options.merge!(block.call) if block

      if !Hash === options
        options = {}
        options[:wrap] = options 
      end

      options[:load]   = true
      options[:suffix] = false
      options[:local]  = false

      require(pathname, options)

      #if file = $LOAD_CACHE[path]
      #  return file.load
      #end

      #if file = Library.find(path, options)
      #  #file.library_activate
      #  $LOAD_CACHE[path] = file
      #  return file.load(options) #acquire(options)
      #end

      ##if options[:load]
      #  __load__(path, options[:wrap])
      ##else
      ##  __require__(path)
      ##end
    end

    #
    # Roll-style loading. First it looks for a specific library via `:`.
    # If `:` is not present it then tries the current loading library.
    # Failing that it fallsback to Ruby itself.
    #
    #   require('facets:string/margin')
    #
    # To "load" the library, rather than "require" it, set the +:load+
    # option to true.
    #
    #   require('facets:string/margin', :load=>true)
    #
    # @param pathname [String]
    #   pathname of feature relative to library's loadpath
    #
    # @return [true, false] if feature was newly required
    #
    def acquire(pathname, options={}) #, &block)
      #options.merge!(block.call) if block
      options[:local] = true
      require(pathname, options)
    end

    #
    # Load up the ledger with a given set of paths.
    #
    def prime(*paths)
      $LEDGER.prime(*paths)
    end

    #
    # Go thru each library and make sure bin path is in path.
    #
    # @todo Should this be defined on Ledger?
    #
    def PATH()
      path = []
      list.each do |name|
        lib = Library[name]
        path << lib.bindir if lib.bindir?
      end
      path.join(RbConfig.windows_platform? ? ';' : ':')
    end

  end

  extend Domain
end
