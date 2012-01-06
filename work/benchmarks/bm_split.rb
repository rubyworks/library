require 'benchmark'

n = 50000
s = "split:this;that"

Benchmark.bmbm do |x|
  x.report("control") {
    n.times {
      s.split(':')
      s.split(';')
    }
  }

  x.report("loop") { 
    n.times {
      s.split(':').map{ |e| e.split(';') }.flatten
    }
  }

  x.report("regexp") { 
    n.times {
      s.split(/[:;]/)
    }
  }
end
