class Library

  # Ledger class track available libraries by library name.
  # It is essentially a hash object.
  #
  class Ledger

    include Enumerable

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
    def add(lib)
      case lib
      when Library
        add_library(lib)
      else
        add_location(lib)
      end
      self
    end

    alias_method :<<, :add

    #
    # Add library to ledger given a location.
    #
    def add_location(location)
      raise TypeError unless File.directory?(location)

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
        #warn "invalid library path -- `#{path}'" if ENV['roll_debug']
      end
    end

    #
    # Add library to ledger given a Library object.
    #
    def add_library(library)
      raise TypeError unless Library === library

      entry = @table[library.name]

      if Array === entry
        entry << library unless entry.include?(library)
      end
    end

    #
    def [](name)
      @table[name.to_s]
    end

    #
    def []=(name, library)
      raise TypeError unless Library === library

      @table[name.to_s] = library
    end

    #
    def each(&block)
      @table.each(&block)
    end

    #
    def size
      @table.size
    end

    #
    def key?(name)
      @table.key?(name.to_s)
    end

    #
    def keys
      @table.keys
    end

    #
    def values
      @table.values
    end

    #
    def inspect
      @table.inspect
    end

  end

end
