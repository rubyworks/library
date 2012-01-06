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
    # Find matching libary files. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their loadpaths.
    #
    def find(path, options={})
      path   = path.to_s

      #suffix = options[:suffix]
      search = options[:search]
      local  = options[:local]

      $stderr.print path if monitor?  # debugging

      # Ruby appears to have a special exception for enumerator!!!
      #return nil if path == 'enumerator' 

      # absolute, home or current path
      case path[0,1]
      when '/', '~', '.'
        $stderr.puts "  (absolute)" if monitor?  # debugging
        return nil
      end

      #if path.index(':') # a specified library
      #  name, fname = path.split(':')
      #  lib  = library(name)
      #  file = lib.include?(fname, options)
      #  raise LoadError, "no such file to load -- #{path}" unless file
      #  $stderr.puts "  (direct)" if monitor?  # debugging
      #  return file
      #end

      if local
        # try the load stack (TODO: just last or all?)
        if feature = $LOAD_STACK.last
        #$LOAD_STACK.reverse_each do |feature|
          lib = feature.library
          #if file = lib.include?(fname, options)
          if file = lib.include?(path, options)
            unless $LOAD_STACK.include?(file)
              $stderr.puts "  (2 stack)" if monitor?  # debugging
              return file
            end
          end
        end
      end

      name, fname = ::File.split_root(path)

      # if the head of the path is the library
      if fname
        lib = Library[name]
        if lib && file = lib.include?(path, options) || lib.include?(fname, options)
          $stderr.puts "  (3 indirect)" if monitor?  # debugging
          return file
        end
      end

      # plain library name?
      if !fname && lib = Library.instance(path)
        if file = lib.default # default file to load
          $stderr.puts "  (5 plain library name)" if monitor?  # debugging
          return file
        end
      end

      # fallback to brute force search, if desired
      #if search #or legacy
        #options[:legacy] = true
        if file = search(path, options)
          $stderr.puts "  (6 brute search)" if monitor?  # debugging
          return file
        end
      #end

      $stderr.puts "  (7 fallback)" if monitor?  # debugging

      nil
    end

    # Brute force search looks through all libraries for a matching file.
    #
    # @param [String] path
    #   file path for which to search
    #
    # options: 
    #   :select -
    #   :suffix -
    #   :legacy -
    #
    # Returns either
    def search(path, options={})
      matches = []

      options = options.merge(:main=>true)

      select  = options[:select]

      #suffix  = options[:suffix] || options[:suffix].nil?
      ##suffix = false if options[:load]
      #suffix = false if Library::SUFFIXES.include?(::File.extname(path))

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *$LEDGER.partition{ |name, libs| Array === libs }

      ## broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if file = lib.find(path, options)
          next if Library.load_stack.last == file
          return file unless select
          matches << file
        end
      end

      ## finally try a broad search on unselected libraries
      unselected.each do |(name, libs)|
        pos = []
        libs.each do |lib|
          if file = lib.find(path, options)
            pos << file
          end
        end
        unless pos.empty?
          latest = pos.sort{ |a,b| b.library.version <=> a.library.version }.first
          return latest unless select
          matches << latest
        end
      end

      # TODO: Should we be doing this?
      # loadpath_search

      select ? matches.uniq : matches.first
    end

    # Search Roll system for current or latest library files. This is useful
    # for plugin loading.
    #
    # This only searches activated libraries or the most recent version
    # of any given library.
    #
    def search_latest(match) #, options={})
      matches = []
      ledger.each do |name, lib|
        lib = lib.sort.first if Array===lib
        lib.loadpath.each do |path|
          find = File.join(lib.location, path, match)
          list = Dir.glob(find)
          list = list.map{ |d| d.chomp('/') }
          matches.concat(list)
        end
      end
      matches
    end

    # @deprecated
    def find_files(match)
      search_latest(match)
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

      options[:wrap]   = true if options and !(Hash===options)
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
