require 'library/library'
require 'library/rubylib'
require 'library/ledger'
require 'library/ledgered'

$LEDGER = Ledger.new
$LOAD_STACK = []
$LOAD_CACHE = {}

class Library
  extend Ledgered
end

# Should this be here? Or just in `ubylibs.rb`?
Library.bootstrap!

