class Library

  #
  #  
  # TODO: I bet we can get rid of LegacyFeature if we modify Feature to handle `nil` library better.
  #
  class LegacyFeature < Feature

    #
    def initialize(pathname)
      @library   = nil
      @fullname  = pathname
      @loadpath  = File.dirname(pathname)    # not that this makes any real sense, but...
      @filename  = File.basename(pathname)
      @extension = nil

      @required = {}
    end

=begin
    #
    def load(options={})
      Library.load_stack << self
      begin
        @required = true if options[:require]
        require_without_library(fullname)
      ensure
        Library.load_stack.pop
      end
    end

    #
    def require(options={})
      Library.load_stack << self
      begin
        load_without_library(fullname, options[:wrap])
      ensure
        Library.load_stack.pop
      end
    end

    #
    def required?
      @required
    end
=end

  end

end
