class Library

  # The Metadata call encapsulates a library's information, in particular
  # `name`, `version` and `load_path`.
  #
  class Metadata

    #
    # Setup new metadata object.
    #
    # @param [String] location
    #   Location of project on disc.
    #
    # @param [Hash] metadata
    #   Manual metadata settings.
    #
    # @option metadata [Boolean] :load
    #   Set to +false+ will prevent metadata being loaded
    #   from .ruby or .gemspec file, but a LoadError will
    #   be raised without `:name` and `:version`.
    #
    def initialize(location, metadata={})
      @location  = location

      @load = metadata.delete(:load)
      @load = true if @load.nil?  # default is true

      @data = {}

      update(metadata)

      if @load
        if not (@data['name'] && @data['version'] && @data['load_path'])
          load_metadata
        end
      else
        raise LoadError unless data['name'] && data['version']   # todo: just name ?
      end
    end

    #
    #
    #
    def update(data)
      @data.update(data.rekey)

      self.name      = data[:name]      if data[:name]
      self.version   = data[:version]   if data[:version]
      self.load_path = data[:load_path] if data[:load_path]
      self.date      = data[:date]      if data[:date]
      self.omit      = data[:omit]
    end

    #
    # Location of library.
    #
    attr :location

    #
    # Local load paths.
    #
    def load_path
      @data[:load_path] || ['lib']
    end

    alias_method :loadpath, :load_path

    #
    # Set the loadpath.
    #
    def load_path=(path)
      case path
      when nil
        path = ['lib']
      when String
        path = path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
      @data[:load_path] = path
    end

    alias_method :loadpath=, :load_path=

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
      @data[:date] || (load_metadata; @data[:data])
    end

    alias_method :released, :date

    # TODO: Should we convert date to Time object?

    #
    # Set the date.
    #
    def date=(date)
      @data[:date] = date
    end

    alias_method :released=, :date=

    #
    # Runtime and development requirements combined.
    #
    def requirements
      @data[:requirements] || (load_metadata; @data[:requirements])
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
    # Does this location have .ruby entries?
    #
    def dotruby?
      @_dotruby ||= File.exist?(File.join(location, '.ruby'))
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
      return unless @load

      if dotruby?
        load_dotruby
      elsif gemspec?
        load_gemspec
      end

      @load = false  # loading is complete
    end

    # Load metadata for .ruby file.
    def load_dotruby
      require 'yaml'

      data = YAML.load_file(File.join(location, '.ruby'))

      update(data)

      #if Hash === data
      #  self.name         = data['name']
      #  self.version      = data['version']      #|| '0.0.0'
      #  self.load_path    = data['load_path']    || ['lib']
      #
      #  self.title        = data['title']        || data['name'].capitalize
      #  self.date         = data['date']
      #
      #  reqs = data['requirements'] || []
      #  reqs.each do |req|
      #    if req['development']
      #      self.development_requirements << [req['name'], req['version']]
      #    else
      #      self.runtime_requirements << [req['name'], req['version']]
      #    end
      #  end
      #end
    end

    # Load metadata from a gemspec. This is a fallback option. It is highly 
    # recommended that a project have a `.ruby` file instead.
    #
    # This method requires that the `dotruby` gem be installed.
    #
    def load_gemspec
      #require 'rubygems'
      require 'dotruby/rubygems'

      text = File.read(gemspec_file)
      if text =~ /\A---/  # TODO: improve
        require 'yaml'
        spec = YAML.load(text)
      else
        spec = eval(text)
      end

      dotruby = DotRuby::Spec.parse_gemspec(spec)

      data = dotruby.to_h

      udpate(data)

      return

      #self.name         = spec.name
      #self.version      = spec.version.to_s
      #self.load_path    = spec.require_paths
      #self.date         = spec.date
      #self.title        = spec.name.capitalize  # for lack of better way

      #spec.dependencies.each do |dep|
      #  if dep.development?
      #    self.development_requirements < [dep.name, dep.version]
      #  else
      #    self.runtime_requirements < [dep.name, dep.verison]
      #  end
      #end
    end

    #
    # Returns the path to the .gemspec file.
    #
    def gemspec_file
      gemspec_system_file || gemspec_local_file
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


