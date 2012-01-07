class Library

  # This extension encapsulates Library's class methods.
  #
  module Domain

    #
    # State of monitoring setting. This is used for debugging.
    #
    def monitor?
      ENV['monitor'] || $MONITOR
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find(path, options={})
      path   = path.to_s

      #suffix = options[:suffix]
      search = options[:search]
      local  = options[:local]
      from   = options[:from]

      $stderr.print path if monitor?  # debugging

      # absolute, home or current path
      #
      # NOTE: Ideally we would try to find a matching path among avaliable libraries
      # so that the library can be activated, however this would probably add a 
      # too much overhead and will by mostly a YAGNI, so we forgo any such
      # functionality, at least for now. 
      case path[0,1]
      when '/', '~', '.'
        $stderr.puts "  (absolute)" if monitor?  # debugging
        return nil
      end

      # from explicit library
      if from
        lib = library(from)
        ftr = lib.find(path, options)
        raise LoadError, "no such file to load -- #{path}" unless file
        $stderr.puts "  (direct)" if monitor?  # debugging
        return ftr
      end

      # check the load stack (TODO: just last or all?)
      if local
        if last = $LOAD_STACK.last
        #$LOAD_STACK.reverse_each do |feature|
          lib = last.library
          if ftr = lib.find(path, options)
            unless $LOAD_STACK.include?(ftr)  # prevent recursive loading
              $stderr.puts "  (2 stack)" if monitor?  # debugging
              return ftr
            end
          end
        end
      end

      name, fname = ::File.split_root(path)

      # if the head of the path is the library
      if fname
        lib = Library[name]
        if lib && ftr = lib.find(path, options) || lib.find(fname, options)
          $stderr.puts "  (3 indirect)" if monitor?  # debugging
          return ftr
        end
      end

      # plain library name?
      if !fname && lib = Library.instance(path)
        if ftr = lib.default  # default feature to load
          $stderr.puts "  (5 plain library name)" if monitor?  # debugging
          return ftr
        end
      end

      # fallback to brute force search
      #if search #or legacy
        #options[:legacy] = true
        if ftr = find_any(path, options)
          $stderr.puts "  (6 brute search)" if monitor?  # debugging
          return ftr
        end
      #end

      $stderr.puts "  (7 fallback)" if monitor?  # debugging

      nil
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
      options = options.merge(:main=>true)

      latest = options[:latest]

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *$LEDGER.partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if ftr = lib.find(path, options)
          next if Library.load_stack.last == ftr
          return ftr
        end
      end

      # finally a broad search on unselected libraries
      unselected.each do |(name, libs)|
        libs = libs.sort
        libs = [libs.first] if latest
        libs.each do |lib|
          ftr = lib.find(path, options)
          return ftr if ftr
        end
      end

      nil
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
      options = options.merge(:main=>true)

      latest = options[:latest]

      matches = []

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *$LEDGER.partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if ftr = lib.find(path, options)
          next if Library.load_stack.last == ftr
          matches << ftr
        end
      end

      # finally a broad search on unselected libraries
      unselected.each do |(name, libs)|
        libs = [libs.sort.first] if latest
        libs.each do |lib|
          ftr = lib.find(path, options)
          matches << ftr if ftr
        end
      end

      matches.uniq
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
      latest = options[:latest]

      matches = []

      ledger.each do |name, libs|
        case libs
        when Array
          libs = libs.sort
          libs = [libs.first] if latest
        else
          libs = [libs]
        end
          
        libs.each do |lib|
          lib.loadpath.each do |path|
            find = File.join(lib.location, path, match)
            list = Dir.glob(find)
            list = list.map{ |d| d.chomp('/') }
            matches.concat(list)
          end
        end
      end

      matches
    end

    #
    # @deprecated
    #
    def find_files(match, options={})
      glob(match, options)
    end

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
        $LOAD_CACHE[pathname] = file
        return feature.acquire(options)
      end

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
    def prime(paths)
      require 'library/rubylib'

      sub_prime(paths)

      $LEDGER['ruby'] = RubyLibrary.new
      $LEDGER
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

  private

    #
    def sub_prime(paths)
      paths.each do |path|
        if File.exist?(File.join(path, '.ruby'))
          $LEDGER << path
        else
          sub_prime(Dir[File.join(path, '*/')])
        end
      end
    end

  end

  extend Domain
end
