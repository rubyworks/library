require 'library'
require 'library/kernel'

paths = ENV['RUBYPATH'].to_s.split(/[:;]/)

Library.prime(paths)

