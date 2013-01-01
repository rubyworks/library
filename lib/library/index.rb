class Library

  protected

  #
  #
  #
  def self.const_missing(name)
    index[name.to_s.downcase] || super(name)
  end

  #
  #
  #
  def self.index
    @_index ||= (
      file = File.expand_path('../library.yml', __dir__)
      YAML.load_file(file)
    )
  end

  #
  # TODO: __dir__ can be removed as of Ruby 2.0.
  #
  def self.__dir__
    File.dirname(__FILE__)
  end

end
