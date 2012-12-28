# Ruby's autoload method does not use the normal require
# mechanisms, therefore if we wish to support it we will
# have to override and create our own system. OTOH Matz
# has said autoload will go away in Ruby 2.0, so maybe
# we can just let this go and not worry about it.

module Kernel
  #alias __autoload__ autoload
end

#class ::Module
#  alias __autoload__ autoload
#end

