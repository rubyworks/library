require 'library'
require 'library/kernel'

paths = ENV['RUBYENV'].to_s.split(/[:;]/)

Library.prime(*paths)

