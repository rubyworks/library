require 'rbconfig'

require 'autoload'
require 'versus'

require 'library/utils'
require 'library/library'
require 'library/rubylib'
require 'library/ledger'
require 'library/ledgered'

$LEDGER = Library::Ledger.new
$LOAD_STACK = []
$LOAD_CACHE = {}

class Library
  extend Ledgered
  # Should this be here? Or just in `ubylibs.rb`?
  bootstrap!
end

