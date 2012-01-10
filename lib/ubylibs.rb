require 'library'
require 'library/kernel'

# Note the plural!!!
list = ENV['RUBYLIBS'].to_s.split(/[:;]/)

Library.prime(*list, :expound=>true)

