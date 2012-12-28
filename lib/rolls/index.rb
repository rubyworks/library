module Rolls

  #
  #
  #
  def self.index
    @index ||= (
      file = File.expand_path('../rolls.yml', __dir__)
      YAML.load_file(file)
    )
  end

protected

  #
  #
  #
  def self.const_missing(name)
    index(name.to_s.downcase) || super(name)
  end

  #
  # TODO: __dir__ can be removed as of Ruby 2.0.
  #
  def self.__dir__
    File.dirname(__FILE__)
  end

end
