# frozen_string_literal: true

# https://ruby-doc.org/stdlib-2.5.0/libdoc/benchmark/rdoc/Benchmark.html
# https://github.com/evanphx/benchmark-ips
# https://github.com/SamSaffron/memory_profiler
# https://github.com/tmm1/stackprof

require_relative '../../config/environment'
require 'memory_profiler'
require 'benchmark/ips'

ActionMailer::Base.perform_deliveries = false

timestamp = Time.now.utc.iso8601
stackprof_file = "script/benchmarks/output/send_assessments_job_benchmark_#{timestamp}_CPU.dump"
flamegraph_file = "script/benchmarks/output/send_assessments_job_benchmark_#{timestamp}_FLM"
memprof_file = "script/benchmarks/output/send_assessments_job_benchmark_#{timestamp}_MEM.log"
benchmark_file = "script/benchmarks/output/send_assessments_job_benchmark_#{timestamp}_BCM.log"
$stdout = File.new(benchmark_file, 'w')
$stdout.sync = true

Benchmark.bm(20) do |x|
  report = MemoryProfiler.report(top: 20) do
    StackProf.run(mode: :wall, out: stackprof_file, interval: 1000, raw: true) do
      x.report('SendAssessmentsJob') do
        SendAssessmentsJob.perform_now
      end
    end
  end
  report.pretty_print(normalize_paths: true, scale_bytes: true, to_file: memprof_file)
end

puts "\n"
puts "\ncat #{memprof_file}"
puts "\nstackprof #{stackprof_file}"
puts "\nstackprof --flamegraph #{stackprof_file} > #{flamegraph_file}"
puts "\nstackprof --flamegraph-viewer=#{flamegraph_file}"

$stdout = STDOUT # disable capture of STDOUT

puts "\n"
puts "\ncat #{memprof_file}"
puts "\nstackprof #{stackprof_file}"
puts "\nstackprof --flamegraph #{stackprof_file} > #{flamegraph_file}"
puts "\nstackprof --flamegraph-viewer=#{flamegraph_file}"