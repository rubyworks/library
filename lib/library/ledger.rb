class Library

  # Ledger class track available libraries by library name.
  # It is essentially a hash object, but with a special way
  # of storing them to track versions. Each have key is the
  # name of a library, as a String, and each value is either
  # a Library object, if that particular version is active,
  # or an Array of available versions of the library if inactive.
  #
  class Ledger

    include Enumerable

    #
    # State of monitoring setting. This is used for debugging.
    #
    def monitor?
      ENV['monitor'] || $MONITOR
    end

    #
    def initialize
      @table = Hash.new(){ |h,k| h[k] = [] }
    end

    #
    # Add a library to the ledger.
    #
    # @param [String,Library]
    #   A path to a ruby library or a Library object.
    #
    # @return [Library] Added library object.
    #
    def add(lib)
      case lib
      when Library
        add_library(lib)
      else
        add_location(lib)
      end
    end

    alias_method :<<, :add

    #
    # Add library to ledger given a location.
    #
    # @return [Library] Added library object.
    #
    def add_location(location)
      begin
        library = Library.new(location)

        entry = @table[library.name]

        if Array === entry
          entry << library unless entry.include?(library)
        else
          # todo: what to do here?
        end
      rescue Exception => error
        warn error.message if ENV['debug']
      end

      library
    end

    #
    # Add library to ledger given a Library object.
    #
    # @return [Library] Added library object.
    #
    def add_library(library)
      #begin
        raise TypeError unless Library === library

        entry = @table[library.name]

        if Array === entry
          entry << library unless entry.include?(library)
        end
      #rescue Exception => error
      #  warn error.message if ENV['debug']
      #end

      library
    end

    #
    # Get library or library version set by name.
    #
    # @param [String] name
    #   Name of library.
    #
    # @return [Library,Array] Library or lihbrary set referenced by name.
    #
    def [](name)
      @table[name.to_s]
    end

    #
    # Set ledger entry.
    #
    # @param [String] Name of library.
    #
    # @raise [TypeError] If library is not a Library object.
    #
    def []=(name, library)
      raise TypeError unless Library === library

      @table[name.to_s] = library
    end

    #
    # Iterate over each ledger entry.
    #
    def each(&block)
      @table.each(&block)
    end

    #
    # Size of the ledger is the number of libraries available.
    #
    # @return [Fixnum] Size of the ledger.
    #
    def size
      @table.size
    end

    #
    # Checks ledger for presents of library by name.
    #
    # @return [Boolean]
    #
    def key?(name)
      @table.key?(name.to_s)
    end

    #
    # Get a list of names of all libraries in the ledger.
    #
    # @return [Array<String>] list of library names
    #
    def keys
      @table.keys
    end

    #
    # Get a list of libraries and library version sets in the ledger.
    #
    # @return [Array<Library,Array>] 
    #   List of libraries and library version sets.
    #
    def values
      @table.values
    end

    #
    # Inspection string.
    #
    # @return [String] Inspection string.
    #
    def inspect
      @table.inspect
    end

    #
    # Limit versions of a library to the given constraint.
    # Unlike `#activate` this does not reduce the possible versions
    # to a single library, but only reduces the number of possibilites.
    #
    # @param [String] name
    #   Name of library.
    #
    # @param [String] constraint
    #   Valid version constraint.
    #
    # @return [Array] List of conforming versions.
    #
    def constrain(name, contraint)
      libraries = self[name]

      return nil unless Array === libraries

      vers = libraries.select do |library|
        library.version.satisfy?(constraint)
      end

      self[name] = vers
    end

    #
    # Activate a library, retrieving a Library instance by name, or name
    # and version, and ensuring only that instance will be returned for
    # all subsequent requests. Libraries are singleton, so once activated
    # the same object is always returned.
    #
    # This method will raise a LoadError if the name is not found.
    #
    # Note that activating all runtime requirements of a library being
    # activated was considered, but decided against. There's no reason
    # to activatea library until it is actually needed. However this is
    # not so when testing, or verifying available requirements, so other
    # methods are provided such as `#activate_requirements`.
    #
    # @param [String] name
    #   Name of library.
    #
    # @param [String] constraint
    #   Valid version constraint.
    #
    # @return [Library]
    #   The activated Library object.
    #
    # @todo Should we also check $"? Eg. `return false if $".include?(path)`.
    #
    def activate(name, constraint=nil)
      raise LoadError, "no such library -- #{name}" unless key?(name)

      library = self[name]

      if Library === library
        if constraint
          unless library.version.satisfy?(constraint)
            raise Library::VersionConflict, library
          end
        end
      else # library is an array of versions
        if constraint
          verscon = Version::Constraint.parse(constraint)
          library = library.select{ |lib| verscon.compare(lib.version) }.max
        else
          library = library.max
        end
        unless library
          raise VersionError, "no library version -- #{name} #{constraint}"
        end

        self[name] = library #constrain(library)
      end

      library
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find_feature(path, options={})
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
      unselected, selected = *partition{ |name, libs| Array === libs }

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
      unselected, selected = *partition{ |name, libs| Array === libs }

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

      each do |name, libs|
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
    # Load up the ledger with a given set of paths and add an instance of
    # the special `RubyLibrary` class after that.
    #
    def prime(*paths)
      require 'library/rubylib'

      sub_prime(*paths)

      add_library(RubyLibrary.new)

      self
    end

    #
    #
    #
    def isolate(name, constraint=nil)
      library = activate(name, constraint)

      # TODO: shouldn't this be done in #activate ?
      acivate_requirements(library)

      unused = []
      each do |name, libs|
        ununsed << name if Array === libs
      end
      unused.each{ |name| @table.delete(name) }

      self
    end

  private

    #
    # Activate library requirements.
    #
    # @todo: checklist is used to prevent possible infinite recursion, but
    #   it might be better to put a flag in Library instead.
    #
    def acivate_requirements(library, development=false, checklist={})
      reqs = development ? library.requirements : library.runtime_requirements

      checklist[library] = true

      reqs.each do |req|
        name = req['name']
        vers = req['version']

        library = activate(name, vers)

        acivate_requirements(library, development, checklist) unless checklist[library]
      end
    end

    #
    # For each path given in `paths` make sure he needed metadata file
    # is present (.ruby or .gemspec) and if so add the path to the ledger.
    #
    # @todo Add a flag to enable/disable gemspec support.
    #
    def sub_prime(*paths)
      paths.each do |path|
        if File.exist?(File.join(path, '.ruby'))
          add_location(path)
        elsif Dir[File.join(path, '*.gemspec')].first
          add_location(path)
        else
          sub_prime(*Dir[File.join(path, '*/')])
        end
      end
    end

  end

end
