if ENV['RUBYOPT'].index('-rubypath') || ENV['RUBYOPT'].index('-roll')
  abort "Remove -rubypath or -roll from RUBYOPT before running these tests." 
end

# Make sure we use local version of files.
#$:.unshift('lib')

