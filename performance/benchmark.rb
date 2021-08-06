# frozen_string_literal: true

# https://ruby-doc.org/stdlib-2.5.0/libdoc/benchmark/rdoc/Benchmark.html
# https://github.com/evanphx/benchmark-ips
# https://github.com/SamSaffron/memory_profiler
# https://github.com/tmm1/stackprof
# https://www.rubydoc.info/stdlib/fileutils/FileUtils
# https://ruby-doc.org/core-2.7.0/File.html

require_relative '../config/environment'

##
# We chose to copy the databse files directly into a temporary backup because
# it is significantly faster than both populating a new database and restoring
# a database with a .sql backup file.
#
# Why not use a rails transaction in benchmark to just roll back the database?
# - Rails 7 will implement many performance improvements, one of which is
#   automatic parallelized queries where queries are not dependent on one
#   another. A transaction in this method would effectively disable the feature
#   for a benchmark and produce performance results that may not be accurate.
#
# ENV Variables:
# - MYSQL_PATH: specify the MySQL datadir manually for temporary DB backups
# - NO_MEMPROF: set this to anything to disable memory-profiler for the benchmark
# - NO_STACKPROF: set this to anything to disable stackprof for the benchmark
# - APP_IN_CI: this is expected to be present in GitHub actions, where MySQL is not local
#
# If `no_exit` is set to true, then the benchmark will not exit with an exit code at
# the end of the benchmark. It will instead return true if passed and false if failed.
def benchmark(name: nil, time_threshold: 3600, setup: nil, teardown: nil, no_exit: false, mode: :total, &block)
  unless %i[real total stime utime].include? mode
    puts 'Mode argument must be any of the following: '
    return
  end

  warn_about_memprof

  if ENV['APP_IN_CI'].nil?
    check_mysql_path_env
    backup(ENV['MYSQL_PATH'])
  end

  ActionMailer::Base.perform_deliveries = false

  timestamp = Time.now.utc.iso8601
  FileUtils.mkdir_p('performance/benchmarks/output') # Create the folder if it doesn't exist already
  stackprof_file = "performance/benchmarks/output/#{name}_#{timestamp}_CPU.dump".tr(':', '-')
  flamegraph_file = "performance/benchmarks/output/#{name}_#{timestamp}_FLM".tr(':', '-')
  memprof_file = "performance/benchmarks/output/#{name}_#{timestamp}_MEM.log".tr(':', '-')
  benchmark_file = "performance/benchmarks/output/#{name}_#{timestamp}_BCM.log".tr(':', '-')
  $stdout = File.new(benchmark_file, 'w') if ENV['CAP_STDOUT']
  $stdout.sync = true if ENV['CAP_STDOUT']

  benchmark_report = nil

  if !setup.nil? && defined?(setup&.call)
    puts 'running setup'
    setup.call
  end
  puts 'starting benchmark'

  Benchmark.bm(20) do |x|
    MemoryProfiler.start unless ENV['NO_MEMPROF']
    StackProf.start(mode: :wall, out: stackprof_file, interval: 1000, raw: true) unless ENV['NO_STACKPROF']
    benchmark_report = x.report(name, &block)
    StackProf.stop unless ENV['NO_STACKPROF']
    MemoryProfiler.stop.pretty_print(normalize_paths: true, scale_bytes: true, to_file: memprof_file) unless ENV['NO_MEMPROF']
  end
  puts 'finished benchmark'
  if !teardown.nil? && defined?(teardown&.call)
    puts 'running teardown'
    teardown.call
  end

  puts 'clearing redis'
  begin
    Sidekiq.redis(&:flushdb)
  rescue Redis::CannotConnectError
    puts 'Redis not found. Skipping.'
  end

  puts "\n"
  puts "\ncat #{benchmark_file}" if ENV['CAP_STDOUT']
  puts "\ncat #{memprof_file}" unless ENV['NO_MEMPROF']
  puts "\nstackprof #{stackprof_file}" unless ENV['NO_STACKPROF']
  puts "\nstackprof --flamegraph #{stackprof_file} > #{flamegraph_file}" unless ENV['NO_STACKPROF']
  puts "\nstackprof --flamegraph-viewer=#{flamegraph_file}" unless ENV['NO_STACKPROF']

  $stdout = STDOUT if ENV['CAP_STDOUT'] # disable capture of STDOUT

  puts File.read(benchmark_file) if ENV['CAP_STDOUT']

  elapsed_time = benchmark_report.send(mode)
  puts "\n\n"
  puts "Acceptable #{mode} time threshold: #{format('%.3f', time_threshold).rjust(10, ' ')}"
  puts "    Actual #{mode} time threshold: #{format('%.3f', elapsed_time).rjust(10, ' ')}"

  restore(ENV['MYSQL_PATH']) if ENV['APP_IN_CI'].nil?

  write_benchmark_json(name, benchmark_report.total, time_threshold)

  if time_threshold < elapsed_time
    puts 'TEST FAILED'
    exit(1) unless no_exit
    false
  else
    puts 'TEST PASSED'
    exit(0) unless no_exit
    true
  end
end

def write_benchmark_json(name, duration, threshold)
  contents = JSON.pretty_generate({
                                    name: name,
                                    branch: `git rev-parse --abbrev-ref HEAD`.strip,
                                    duration: duration,
                                    threshold: threshold,
                                    passed: duration < threshold,
                                    stackprof_enabled: ENV['NO_STACKPROF'].nil?,
                                    memprof_enabled: ENV['NO_MEMPROF'].nil?,
                                    created_at: Time.now.iso8601
                                  })
  output_file = "performance/benchmarks/output/benchmark_result_#{Time.now.to_i}.json"
  File.open(output_file, 'w') { |f| f.write(contents) }
end

def check_mysql_path_env
  return unless ENV['MYSQL_PATH'].nil? || !File.directory?(ENV['MYSQL_PATH'])

  puts 'MYSQL_PATH env variable not found. Trying to find dir automatically'
  sql = 'SHOW VARIABLES WHERE Variable_Name LIKE "%dir"'
  result = ActiveRecord::Base.connection.execute(sql).find { |f| f.first == 'datadir' }&.last
  if result.nil?
    puts 'Could not find the MySQL datadir!'
    puts 'Set the MYSQL_PATH ENV variable to the folder where databases are stored'
    puts 'If installed on Mac OS with homebrew this is likely at /usr/local/var/mysql/'
    puts 'If installed on Ubuntu this is likely at /var/lib/mysql/'
    exit 1
  end
  puts "Found MYSQL_PATH at #{result}"
  ENV['MYSQL_PATH'] = result
end

def warn_about_memprof
  return unless (Patient.count > 100_000) && (!ENV['NO_MEMPROF'])

  puts "\n\nWARNING!!!"
  puts 'Using memory-profiler with large tasks can lead to huge amounts of memory usage.'
  puts 'Your database appears to be very large. Consider disabling memory-profiler in the benchmark by running'
  puts "export NO_MEMPROF='true'"
  puts 'or prepending this to the start of your command'
  puts "NO_MEMPROF='true' <command>\n\n"
end

def expected_db_path(mysql_path)
  File.join(mysql_path, ActiveRecord::Base.connection.current_database)
end

def expected_backup_path(mysql_path)
  File.join(mysql_path, "#{ActiveRecord::Base.connection.current_database}-benchmark-backup")
end

def db_exists?(mysql_path)
  File.directory? expected_db_path(mysql_path)
end

def backup_exists?(mysql_path)
  File.directory? expected_backup_path(mysql_path)
end

def remove_db(mysql_path)
  FileUtils.rm_rf expected_db_path(mysql_path)
end

def remove_backup(mysql_path)
  FileUtils.rm_rf expected_backup_path(mysql_path)
end

def backup(mysql_path)
  puts "Backing up DB for benchmarking from #{expected_db_path(mysql_path)} to #{expected_backup_path(mysql_path)}"
  raise Exception.new, "DB must exist at #{expected_db_path(mysql_path)} before benchmarking!" unless db_exists?(mysql_path)

  if backup_exists?(mysql_path)
    puts('Removing old DB backup')
    remove_backup(mysql_path)
  end
  FileUtils.cp_r expected_db_path(mysql_path), expected_backup_path(mysql_path), preserve: true
end

def restore(mysql_path)
  puts "Restoring DB for benchmarking from #{expected_backup_path(mysql_path)} to #{expected_db_path(mysql_path)}"
  raise Exception.new, "DB must exist at #{expected_backup_path(mysql_path)} before benchmarking!" unless backup_exists?(mysql_path)

  if db_exists?(mysql_path)
    puts('Removing DB before restoring')
    remove_db(mysql_path)
  end
  FileUtils.cp_r expected_backup_path(mysql_path), expected_db_path(mysql_path), preserve: true
  # Cleanup backup to avoid taking up unnecessary storage space
  puts 'Removing temporary DB backup folder'
  remove_backup(mysql_path)
end
