module Rolls

  require 'rolls/index'
  require 'rolls/core_ext'
  require 'rolls/version'
  require 'rolls/ledger'
  require 'rolls/library'
  require 'rolls/rubylib'

  #
  #
  #
  $LEDGER = Ledger.new

  #
  # When loading files, the current library doing the loading is pushed
  # on this stack, and then popped-off when it is finished.
  #
  $LOAD_STACK = []

  #
  #
  #
  $LOAD_CACHE = {}

  #
  #
  #
  def self.bootstrap!
    reset!
    Kernel.require 'library/kernel'
  end

  #
  #
  #
  def self.reset!
    #$LEDGER = Ledger.new
    $LOAD_STACK = []
    $LOAD_CACHE = {}

    if File.exist?(lock_file)
      ledger = YAML.load_file(lock_file)
      $LEDGER.replace(ledger)
    else
      list = path_list
      $LEDGER.prime(*list, :expound=>true)
    end
  end

  #
  # Library lock file.
  #
  def self.lock_file
    File.expand_path("~/.ruby/#{ruby_version}.roll")
  end

  #
  #
  #
  def self.ruby_version
    ENV['RUBY'] || RUBY_VERSION
  end

  #
  # Library list file.
  #
  def self.path_file
    File.expand_path("~/.ruby/#{ruby_version}.path")
    #File.expand_path('~/.ruby-path')
  end

  #
  # TODO: Should the path file take precedence over the environment variable?
  #
  def self.path_list
    if list = ENV['RUBY_PATH']
      list.split(/[:;]/)
    elsif File.exist?(path_file)
      File.readlines(path_file).map{ |x| x.strip }.reject{ |x| x.empty? || x =~ /^\s*\#/ }
    elsif ENV['GEM_PATH']
      ENV['GEM_PATH'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
    elsif ENV['GEM_HOME']
      ENV['GEM_HOME'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
    else
      warn "No Ruby libraries."
      []
    end
  end

end
