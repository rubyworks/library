if ENV['RUBYOPT'].index('-rubylibs') || ENV['RUBYOPT'].index('-roll')
  abort "Remove -rubylibs or -roll from RUBYOPT before running these tests." 
end

# Make sure we use local version of files.
#$:.unshift('lib')

def fixtures
  @_fixtures ||= File.dirname(__FILE__) + '/../fixtures'
end

