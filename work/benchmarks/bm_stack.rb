require 'benchmark'

n = 50000

s0 = []

s1 = []
s2 = []

class S
  def initialize(t1, t2)
    @t1 = t1
    @t2 = t2
  end
end

Benchmark.bmbm do |x|
  x.report("two stacks") {
    n.times {
      s1 << "thing1"
      s2 << "thing2"
    }
  }

  x.report("one stack") { 
    n.times {
      s0 << S.new("thing1", "thing2")
    }
  }
end
