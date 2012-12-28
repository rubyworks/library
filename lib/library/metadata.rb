class Library

  #$DEBUG = true
  require 'yaml'  # TODO: this should not be needed here

  # The Metadata class encapsulates a library's basic information, in particular
  # name, version and load path.
  #
  class Metadata

    #
    # Setup new metadata object.
    #
    # @param [String] location
    #   Location of project on disc.
    #
    # @param [Hash] metadata
    #   Set metadata manually, instead of loading from file.
    #
    def initialize(location, metadata=nil)
      @location  = location

      #@load = metadata.delete(:load)
      #@load = true if @load.nil?  # default is true

      @data = {}

      if metadata && !metadata.empty?
        update(metadata)
      else
        load_metadata
      end

      raise "#{location} has no name or version" unless @data[:name] && @data[:version]
    end

    #
    # Update metadata with data hash.
    #
    # @param [Hash] data
    #   Data to merge into metadata table.
    #
    def update(data)
      data = data.rekey

      data.each do |key, value|
        __send__("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    #
    # Location of library.
    #
    attr :location

    #
    # Paths, the only one used currently is `load`.
    #
    def paths
      @data[:paths]
    end

    #
    # Set paths map.
    #
    # @param [Hash] paths
    #   Paths map.
    #
    def paths=(paths)
      @data[:paths] = (
        h = {}
        paths.each do |key, val|
          val = (String === val ? split_path(val) : val)
          h[key.to_sym] = Array(val)
        end
        h
      )
    end

    #
    # Local load paths.
    #
    def loadpath
      @data[:paths] ||= {}
      @data[:paths][:load] || ['lib']
    end

    alias_method :load_path, :loadpath

    #
    # Set the load paths.
    #
    def loadpath=(path)
      case path
      when nil
        path = ['lib']
      when String
        path = split_path(path)
      end
      @data[:paths] ||= {}
      @data[:paths][:load] = path
    end

    alias_method :load_path=, :loadpath=

    #
    # Name of library.
    #
    def name
      @data[:name]
    end

    #
    # Set name.
    #
    def name=(string)
      @data[:name] = string.to_s if string
    end

    #
    # Version number.
    #
    # Technically, a library should not appear in a ledger list if it lacks
    # a version. However, just in case this occurs (say by a hand edited
    # environment) we fallback to a version of '0.0.0'.
    #
    def version
      @data[:version] ||= Version.new('0.0.0')
    end

    #
    # Set version, converts string into Version number class.
    #
    def version=(string)
      @data[:version] = Version.new(string) if string
    end

    #
    # Release date.
    #
    def date
      @data[:date]
    end

    alias_method :released, :date

    #
    # Set the date.
    #
    # TODO: Should we convert date to Time object?
    #
    def date=(date)
      @data[:date] = date
    end

    alias_method :released=, :date=

    #
    # Runtime and development requirements combined.
    #
    def requirements
      @data[:requirements]
    end

    #
    # Runtime and development requirements combined.
    #
    def requirements=(requirements)
      @data[:requirements] = requirements
    end

    #
    # Runtime requirements.
    #
    def runtime_requirements
      @runtime_requirements ||= requirements.reject{ |r| r['development'] }
    end

    #
    # Development requirements.
    #
    def development_requirements
      @development_requirements ||= requirements.select{ |r| r['development'] }
    end

    #
    # Access to non-primary metadata.
    #
    def [](name)
      @data[name.to_sym]
    end

    # TODO: Should we support +omit+ setting, or should we add a way to 
    # exclude loctions via environment setting?

    #
    # Omit from any ledger?
    #
    def omit?
      @omit
    end

    #
    # Set omit.
    #
    def omit=(boolean)
      @omit = boolean
    end

    #
    # Does this location have .index file?
    #
    def dotindex?
      @_dotindex ||= File.exist?(File.join(location, '.index'))
    end

    #
    # Deterime if the location is a gem location. It does this by looking
    # for the corresponding `gems/specification/*.gemspec` file.
    #
    def gemspec?
      #return true if Dir[File.join(location, '*.gemspec')].first
      pkgname = File.basename(location)
      gemsdir = File.dirname(location)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      Dir[File.join(specdir, "#{pkgname}.gemspec")].first
    end

    #
    # Access to complete gemspec. This is for use with extended metadata.
    #
    def gemspec
      @_gemspec ||= (
        require 'rubygems'
        ::Gem::Specification.load(gemspec_file)
      )
    end

    #
    # Verify that a library's requirements are all available in the ledger.
    # Returns a list of `[name, version]` of Libraries that were not found.
    #
    # @return [Array<String,String>] List of missing requirements.
    #
    def missing_requirements(development=false) #verbose=false)
      libs, fail = [], []
      reqs = development ? requirements : runtime_requirements
      reqs.each do |req|
        name = req['name']
        vers = req['version']
        lib = Library[name, vers]
        if lib
          libs << lib
          #$stdout.puts "  [LOAD] #{name} #{vers}" if verbose
          unless libs.include?(lib) or fail.include?([lib,vers])
            lib.verify_requirements(development) #verbose)
          end
        else
          fail << [name, vers]
          #$stdout.puts "  [FAIL] #{name} #{vers}" if verbose
        end
      end
      return fail
    end

    #
    # Like {#missing_requirements} but returns `true`/`false`.
    #
    def missing_requirements?(development=false)
      list = missing_requirements(development=false)
      list.empty? ? false : true
    end

    #
    # Returns hash of primary metadata.
    #
    # @return [Hash] primary metdata
    #
    def to_h
      { 'location'     => location,
        'name'         => name,
        'version'      => version.to_s,
        'date'         => date.to_s,
        'load_path'    => load_path,
        'requirements' => requirements,
        'omit'         => omit
      }
    end

  private

    # Load metadata.
    def load_metadata
      if dotindex?
        load_dotindex
      elsif gemspec?
        load_gemspec
      end
    end

    #
    # Load metadata for .index file.
    #
    def load_dotindex
      file = File.join(location, '.index')
      data = YAML.load_file(file)
      update(data)
    end

    # Load metadata from a gemspec. This is a fallback option. It is highly 
    # recommended that a project have a `.index` file instead.
    #
    # This method requires that the `metaspec` gem be installed.  # TODO: metaspec gem name ?
    #
    # TODO: Deprecate YAML form of gemspec, RubyGems no longer supports it.
    #
    def load_gemspec
      text = File.read(gemspec_file)
      if text =~ /\A---/  
        require 'yaml'
        spec = YAML.load(text)
      else
        spec = eval(text) #, gemspec_file)
      end

      data = {}
      data[:name]    = spec.name
      data[:version] = spec.version.to_s
      data[:date]    = spec.date

      data[:paths] = {
        'load' => spec.require_paths 
      }

      data[:requirements] = []

      spec.runtime_dependencies.each do |dep|
        req = { 
          'name'    => dep.name,
          'version' => dep.requirement.to_s
        }
        data[:requirements] << req
      end

      spec.development_dependencies.each do |dep|
        req = { 
          'name'        => dep.name,
          'version'     => dep.requirement.to_s,
          'development' => true
        }
        data[:requirements] << req
      end

      update(data)
    end

    #
    # Returns the path to the .gemspec file.
    #
    def gemspec_file
      gemspec_file_system || gemspec_file_local
    end

    #
    # Returns the path to a gemspec file located in the project location,
    # if it exists. Otherwise returns +nil+.
    #
    def gemspec_file_local
      @_gemspec_file_local ||= Dir[File.join(location, '*.gemspec')].first
    end

    #
    # Returns the path to a gemspec file located in the gems/specifications
    # directory, if it exists. Otherwise returns +nil+.
    #
    def gemspec_file_system
      @_gemspec_file_system ||= (
        pkgname = File.basename(location)
        gemsdir = File.dirname(location)
        specdir = File.join(File.dirname(gemsdir), 'specifications')
        Dir[File.join(specdir, "#{pkgname}.gemspec")].first
      )
    end

    #
    #def require_indexer
    #  require 'rubygems'
    #  require 'indexer'
    #  require 'indexer/rubygems'
    #end

    #
    def split_path(path)
      path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
    end

  end

end



    # Fake
    #module Gem
    #  class Specification < Hash
    #    def initialize
    #      yield(self)
    #    end
    #    def method_missing(s,v=nil,*a,&b)
    #      case s.to_s
    #      when /=$/
    #        self[s.to_s.chomp('=').to_sym] = v
    #      else
    #        self[s]
    #      end
    #    end
    #  end
    #end


