# frozen_string_literal: true

# https://ruby-doc.org/stdlib-2.5.0/libdoc/benchmark/rdoc/Benchmark.html
# https://github.com/evanphx/benchmark-ips
# https://github.com/SamSaffron/memory_profiler
# https://github.com/tmm1/stackprof

require_relative '../../config/environment'
require 'memory_profiler'
require 'benchmark/ips'

ActionMailer::Base.perform_deliveries = false

Benchmark.bm(20) do |x|
  report = MemoryProfiler.report(top: 20) do
    StackProf.run(mode: :wall, out: 'script/benchmarks/send_assessments_job_benchmark_CPU.dump', interval: 1000) do
      x.report('SendAssessmentsJob') do
        SendAssessmentsJob.perform_now
      end
    end
  end
  report.pretty_print(normalize_paths: true, scale_bytes: true, to_file: 'script/benchmarks/send_assessments_job_benchmark_MEM.log')
end

puts "\n"
puts 'cat script/benchmarks/send_assessments_job_benchmark_MEM.log'
puts 'stackprof script/benchmarks/send_assessments_job_benchmark_CPU.dump'

