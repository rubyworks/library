projects = File.dirname(__FILE__) + '/projects'

ENV['RUBYPATH'] = projects

# reset ledger
#$LEDGER = Roll::Ledger.new

# okay now we can require ubypath
require 'ubypath'

