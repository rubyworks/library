class Library
  require 'roll/library/requirements'

  # The Metadata call encapsulates a library's package,
  # profile and requirements information.
  class Metadata

    # New metadata object.
    def initialize(location, data={})
      @location  = location

      self.name      = data[:name]     if data[:name]
      self.version   = data[:version]  if data[:version]
      self.load_path = data[:loadpath] if data[:loadpath]

      @loaded = false

      load_metadata if not primary_loaded?
    end

    # Is the primary metadata loaded? Primary metadata is the name,
    # version and loadpath.
    def primary_loaded?
      @name && @version && @loadpath
    end

    # Location of library.
    attr :location


    # Local load paths.
    def load_path
      @load_path || ['lib']
    end

    alias_method :loadpath, :load_path

    # Set the loadpath.
    def load_path=(path)
      case path
      when nil
        path = ['lib']
      when String
        path = path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
      @load_path = path
    end

    alias_method :loadpath=, :load_path=

    # Name of library.
    def name
      @name
    end

    # Set name.
    def name=(string)
      @name = string.to_s if string
    end

    # Version number. Technically, a library should not appear in a ledger
    # list if it lacks a VERSION file. However, just in case this occurs
    # (say by a hand edited environment) we fallback to a version of '0.0.0'.
    def version
      @version
    end

    # Set version, converts string into Version number class.
    def version=(string)
      @version = Version.new(string) if string
    end

    # Release date.
    def date
      @date || (load_metadata; @date)
    end

    # Alias for `#date`.
    alias_method :released, :date

    #
    def date=(date)
      @date = date
    end

    # Display name, e.g. "ActiveRecord"
    def title
      @title || (load_metadata; @title)
    end

    #
    def title=(title)
      @title = title.to_s if title
    end

    #
    def runtime_requirements
      @runtime_requirements ||= (load_metadata; @runtime_requirements)
    end

    #
    def development_requirements
      @development_requirements || (load_metadata; @development_requirements)
    end

    #
    def requirements
      runtime_requirements + development_requirements
    end

    # Omit from any ledger?
    #
    # TODO: Should we support +omit+ setting, or should we add a way to 
    # exclude loctions from from the environment?
    def omit?
      @omit
    end

    # Does this location have .ruby entries?
    def dotruby?
      @dot_ruby ||= File.exist?(File.join(location, '.ruby'))
    end

    # Deterime if the location is a gem location. It does this by looking
    # for the corresponding `gems/specification/*.gemspec` file.
    def gemspec?
      #return true if Dir[File.join(location, '*.gemspec')].first
      pkgname = File.basename(location)
      gemsdir = File.dirname(location)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      Dir[File.join(specdir, "#{pkgname}.gemspec")].first
    end

    # Access to complete gemspec. This is for use with extended metadata.
    def gemspec
      @_gemspec ||= (
        require 'rubygems'
        ::Gem::Specification.load(gemspec_file)
      )
    end

    # Returns a list of Library and/or [name, vers] entries.
    # A Libray entry means the library was loaded, whereas the
    # name/vers array means it failed. (TODO: Best way to do this?)
    #
    # TODO: don't do stdout here
    def verify_requirements(verbose=false)
      libs, fail = [], []
      runtime_requirements.each do |(name, vers)|
        lib = Library[name, vers]
        if lib
          libs << lib
          $stdout.puts "  [LOAD] #{name} #{vers}" if verbose
          unless libs.include?(lib) or fail.include?(luib)
            lib.requirements.verify(verbose)
          end
        else
          fail << [name, vers]
          $stdout.puts "  [FAIL] #{name} #{vers}" if verbose
        end
      end
      return libs, fail
    end

    #
    def to_h
      { :location     => location,
        :name         => name,
        :version      => version.to_s,
        :loadpath     => loadpath,
        :title        => title,
        :date         => date,
        :requirements => requirements
      }
    end

  private

    # Load metadata.
    def load_metadata
      return if @loaded

      @loaded = true

      @runtime_requirements     = []
      @development_requirements = []

      if dotruby?
        load_dotruby
      elsif gemspec?
        load_gemspec
      end
    end

    # Load metadata for .ruby file.
    def load_dotruby
      require 'yaml'

      data = YAML.load_file(File.join(location, '.ruby'))

      if Hash === data
        self.name         = data['name']
        self.version      = data['version']      #|| '0.0.0'
        self.load_path    = data['load_path']    || ['lib']

        self.title        = data['title']
        self.date         = data['date']

        data['requirements'].each do |req|
          if req['development']
            self.development_requirements << [req['name'], req['version']]
          else
            self.runtime_requirements << [req['name'], req['version']]
          end
        end
      end
    end

    # Load metadata from a gemspec.
    def load_gemspec
      require 'rubygems'

      text = File.read(gemspec_file)
      if text =~ /\A---/  # TODO: improve
        require 'yaml'
        spec = YAML.load(text)
      else
        spec = eval(text)
      end

      self.name         = spec.name
      self.version      = spec.version.to_s
      self.load_path    = spec.require_paths
      self.date         = spec.date
      self.title        = spec.name.capitalize  # for lack of better way

      spec.dependencies.each do |dep|
        if dep.development?
          self.development_requirements < [dep.name, dep.version]
        else
          self.runtime_requirements < [dep.name, dep.verison]
        end
      end
    end

    # Returns the path to the .gemspec file.
    def gemspec_file
      gemspec_system_file || gemspec_local_file
    end

    # Returns the path to a gemspec file located in the project location,
    # if it exists. Otherwise returns +nil+.
    def gemspec_file_local
      @_gemspec_file_local ||= Dir[File.join(location, '*.gemspec')].first
    end

    # Returns the path to a gemspec file located in the gems/specifications
    # directory, if it exists. Otherwise returns +nil+.
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

    #--
    #def gemspec_parse
    #  if !gemspec_local_file
    #    gemspec_parse_location
    #  else
    #    @name     = gem.name
    #    @version  = gem.version.to_s
    #    @loadpath = gem.require_paths
    #    #@date     = gem.date
    #  end
    #end
    #++

=begin
    # Extract the minimal metadata from a gem location. This does not parse
    # the actual gemspec, but parses the gem locations basename and looks for
    # the presence of a `.require_paths` file. This is much more efficient.
    def gemspec_parse_location
      pkgname = File.basename(location)
      if md = /^(.*?)\-(\d+.*?)$/.match(pkgname)
        self.name     = md[1]
        self.version  = md[2]
      else
        raise "Could not parse name and version from gem at `#{location}`."
      end
      file = File.join(location, '.require_paths')
      if File.exist?(file)
        text = File.read(file)
        self.loadpath = text.strip.split(/\s*\n/)
      else
        self.loadpath = ['lib'] # TODO: also ,'bin'] ?
      end
    end
=end

#    # Save minimal `.ruby` entries.
#    def dotruby_save
#      require 'fileutils'
#      dir = File.join(location, '.ruby')
#      FileUtils.mkdir(dir)
#      File.open(File.join(dir, 'name'), 'w'){ |f| f << name }
#      File.open(File.join(dir, 'version'), 'w'){ |f| f << version.to_s }
#      File.open(File.join(dir, 'loadpath'), 'w'){ |f| f << loadpath.join("\n") }
#    end

=begin
    # Ensure there is a set of dotruby entries. Presently this just checks to
    # see if there are .ruby/ entries. If not and it is a gem location, it will
    # use the gem's information to write the .ruby entries.
    #
    # NOTE: There is no further fallback, as there does not seem to be any other
    # reliable means for determining the minimum information (though Bundler
    # is pushing the version.rb file, but I am suspect of this design).
    # There is also the possible VERSION file, but there are at least three
    # differnt formats for this file in common use --I am not sure it's worth
    # the coding effort. Just add the .ruby entires already!
    def dotruby_ensure
      return location if dotruby?
      if gemspec?
        gemspec_parse
        #dotruby_save
        return location
      else
        return nil
      end
    end
=end

