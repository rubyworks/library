class Library

  # The Library::Version class is essentially a tuple (immutable array)
  # with special comparision operators.
  #
  class Version
    include Comparable
    include Enumerable

    #
    # Convenience alias for ::new.
    #
    def self.[](*args)
      new(*args)
    end

    # Parses a string constraint returning the operation as a lambda.
    #
    # @param constraint [String]
    #   valid version constraint, e.g. ">1.0" and "1.0+"
    #
    # @return [Proc] procedure for making contraint comparisons
    #
    def self.constraint_lambda(constraint)
      op, val = *parse_constraint(constraint)
      lambda do |t|
        case t
        when Version
          t.send(op, val)
        else
          Version.new(t).send(op, val)
        end
      end
    end

    #
    # Converts a constraint into an operator and value.
    #
    # @param [String]
    #   valid version constraint , e.g. "= 2.1.3"
    #
    # @return [Array<String>] operator and version number pair
    #
    def self.parse_constraint(constraint)
      constraint = constraint.strip
      re = %r{^(=~|~>|<=|>=|==|=|<|>)?\s*(\d+(:?\.\S+)*)$}
      if md = re.match(constraint)
        if op = md[1]
          op = '=~' if op == '~>'
          op = '==' if op == '='
          val = new(*md[2].split(/\W+/))
        else
          op = '=='
          val = new(*constraint.split(/\W+/))
        end
      else
        raise ArgumentError, "invalid constraint"
      end
      return op, val
    end

    #
    # Parse common Hash-based version, i.e. Jeweler format.
    #
    # @param [Hash] version hash
    #
    # @return [Library::Version] instance of Version
    #
    def self.parse_hash(data)
      data = data.inject({}){ |h,(k,v)| h[k.to_sym] = v; h }
      if data[:major]
        vers = data.values_at(:major, :minor, :patch, :build)
      else
        vers = data[:vers] || data[:version]
      end
      new vers
    end

    #
    # Parse YAML-based version.
    # TODO: deprecate ?
    #
    def parse_yaml(yaml)
      require 'yaml'
      parse_hash( YAML.load(yaml) )
    end

    #
    # Instantiate new instance of Version.
    #
    def initialize(*args)
      args   = args.flatten.compact
      args   = args.join('.').split(/\W+/)
      @tuple = args.map{ |i| /^\d+$/ =~ i.to_s ? i.to_i : i }
    end

    #
    # Returns string representation of version, e.g. "1.0.0".
    #
    # @return [String] version number in dot format
    #
    def to_s
      @tuple.compact.join('.')
    end

    #
    # Library::Version is not technically a String-type. This is here
    # only becuase `File.join` calls it instead of #to_s.
    #
    # @return [String] version number in dot format
    #
    def to_str
      @tuple.compact.join('.')
    end

    #
    #def inspect; to_s; end

    #
    # Access indexed segment of version number.
    # Returns `0` if index is non-existant.
    #
    # @param index [Integer] a segment index of the version
    #
    # @return [Integer, String] version segment
    #
    def [](index)
      @tuple.fetch(index,0)
    end

    #
    # "Spaceship" comparsion operator.
    #
    # @param other [Library::Version, Array]
    #   a Library::Version or equvalent Array to compare
    #
    # @return [Integer]
    #   `-1`, `0`, or `1` for less, equal or greater, respectively
    #
    def <=>(other)
      [size, other.size].max.times do |i|
        c = self[i] <=> (other[i] || 0)
        return c if c != 0
      end
      0
    end

    #
    # Pessimistic constraint (like '~>' in gems).
    #
    # @param other [Library::Version]
    #   another instance of version
    #
    # @return [Boolean] match pessimistic constraint?
    #
    def =~(other)
      #other = other.to_t
      upver = other.tuple.dup
      i = upver.index(0)
      i = upver.size unless i
      upver[i-1] += 1
      self >= other && self < upver
    end

    #
    # Major is the first number in the version series.
    #
    def major ; @tuple[0] ; end

    #
    # Minor is the second number in the version series.
    #
    def minor ; @tuple[1] || 0 ; end

    #
    # Patch is third number in the version series.
    #
    def patch ; @tuple[2] || 0 ; end

    #
    # Build returns the remaining portions of the version
    # tuple after +patch+ joined by '.'.
    #
    # @return [String] version segments after the 3rd in point-format
    #
    def build
      @tuple[3..-1].join('.')
    end

    #
    # Iterate over each version segment.
    #
    def each(&block)
      @tuple.each(&block)
    end

    #
    # Size of version tuple.
    #
    # @return [Integer] number of segments
    #
    def size
      @tuple.size
    end

    # Delegate to the array.
    #def method_missing(sym, *args, &blk)
    #  @tuple.__send__(sym, *args, &blk) rescue super
    #end

    #
    # Does this version satisfy a given constraint?
    #
    # TODO: Support multiple constraints ?
    #
    def satisfy?(constraint)
      c = Constraint.parse(constraint)
      send(c.operator, c.number)
    end

    protected

    #
    # The internal tuple modeling the version number.
    #
    # @return [Array] internal tuple representing the version
    #
    def tuple
      @tuple
    end

  end

  # VersionError is raised when a requested version cannot be found.
  #
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  #
  class VersionConflict < ::LoadError  # :nodoc:

    #
    # Setup conflict error instance.
    #
    def initialize(lib1, lib2=nil)
      @lib1 = lib1
      @lib2 = lib2
    end

    #
    #
    #
    def to_s
      if @lib2
        @lib1.inspect + " vs. " + @lib2.inspect
      else
        "previously selected version -- #{@lib1.inspect}"
      end
    end

  end

  class Version

    # The Constraint class models a single version equality or inequality.
    # It consists of the operator and the version number.
    #--
    # TODO: Please improve me!
    #
    # TODO: This should ultimately replace the class methods of Version::Number.
    #
    # TODO: Do we need to support version "from-to" spans ?
    #++
    class Constraint

      #
      def self.parse(constraint)
        return constraint if self === constraint
        new(constraint)
      end

      #
      def self.[](operator, number)
        new([operator, number])
      end

      #
      def initialize(constraint)
        @operator, @number = parse(constraint || '0+')

        case constraint
        when Array
          @stamp = "%s %s" % [@operator, @number]
        when String
          @stamp = constraint || '0+'
        end
      end

      # Constraint operator.
      attr :operator

      # Verison number.
      attr :number

      #
      def to_s
        @stamp
      end

      # Converts the version into a constraint string recognizable
      # by RubyGems.
      #--
      # TODO: Better name Constraint#to_s2.
      #++
      def to_gem_version
        op = (operator == '=~' ? '~>' : operator)
        "%s %s" % [op, number]
      end

      # Convert constraint to Proc object which can be
      # used to test a version number.
      def to_proc
        lambda do |v|
          n = Version::Number.parse(v)
          n.send(operator, number)
        end
      end

      #
      def compare(version)
        version.send(operator, number)
      end

    private

      #
      def parse(constraint)
        case constraint
        when Integer
          op, val = "==", val.to_s
        when Array
          op, val = constraint   # num?
        when /^(.*?)\~$/
          op, val = "=~", $1
        when /^(.*?)\+$/
          op, val = ">=", $1
        when /^(.*?)\-$/
          op, val = "<", $1
        when /^(=~|~>|<=|>=|==|=|<|>)?\s*(\d+(:?[-.]\w+)*)$/
          if op = $1
            op = '=~' if op == '~>'
            op = '==' if op == '='
            val = $2.split(/\W+/)
          else
            op = '=='
            val = constraint.split(/\W+/)
          end
        else
          raise ArgumentError #constraint.split(/\s+/)
        end
        return op, Version.new(*val) #Version::Number.new(*val)
      end

      # Parse package entry into name and version constraint.
      #def parse(package)
      #  parts = package.strip.split(/\s+/)
      #  name = parts.shift
      #  vers = parts.empty? ? nil : parts.join(' ')
      # [name, vers]
      #end

    public

      # Parses a string constraint returning the operation as a lambda.
      def self.constraint_lambda(constraint)
        new(constraint).to_proc
      end

      # Parses a string constraint returning the operator and value.
      def self.parse_constraint(constraint)
        c = new(constraint)
        return c.operator, c.number
      end

    end

  end

end
