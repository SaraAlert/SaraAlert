# frozen_string_literal: true

require_relative "../../config/environment"

# Any benchmarking setup goes here...



Benchmark.ips do |x|
  x.report("before") { }
  x.report("after") { }

  x.compare!
end
