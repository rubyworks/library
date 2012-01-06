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
        add_path(lib)
      end
      self
    end

    alias_method :<<, :add

    #
    def add_path(path)
      raise TypeError unless File.directory?(path)

      begin
        library = Library.new(path, true)
        @table[library.name] << library
      rescue Exception => error
        warn error.message if ENV['debug']
        #warn "invalid library path -- `#{path}'" if ENV['roll_debug']
      end
    end

    #
    def add_library(library)
      raise TypeError unless Library === library

      @table[library.name] << library
    end

    #
    def [](name)
      @table[name.to_s]
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
