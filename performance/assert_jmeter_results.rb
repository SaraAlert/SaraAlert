# frozen_string_literal: true

require 'csv'

config = [
  {
    label: '01_01_SA_visit_sign_in',
    failure_thresholds: {}
  },
  {
    label: '01_02_SA_sign_in',
    failure_thresholds: {}
  },
  {
    label: '01_03_SA_dashboard',
    failure_thresholds: {
      avg_latency: 4_000,
      avg_elapsed: 4_000,
      failure_percent: 0
    }
  },
  {
    label: '01_04_SA_assigned_users',
    failure_thresholds: {
      avg_latency: 32_000,
      max_latency: 60_000,
      avg_elapsed: 32_000,
      max_elapsed: 60_000,
      failure_percent: 0
    }
  },
  {
    label: '01_05_SA_patients',
    failure_thresholds: {
      avg_latency: 10_000,
      max_latency: 15_000,
      avg_elapsed: 10_000,
      max_elapsed: 15_000,
      failure_percent: 0
    }
  }
]

jtl_path = ENV['JTL_PATH'] || 'jmeter.jtl'
jtl_rows = CSV.read(jtl_path, headers: true)

# rows that do not end with (-0 ... -000)
jtl_rows.filter { |a| a['label'] !~ /-\d{1,}/ }

# https://stackoverflow.com/questions/36156305/console-table-format-in-ruby
class Array
  def to_table
    column_sizes = reduce([]) do |lengths, row|
      row.each_with_index.map { |iterand, index| [lengths[index] || 0, iterand.to_s.length].max }
    end
    puts head = '-' * (column_sizes.inject(&:+) + (3 * column_sizes.count) + 1)
    each do |row|
      row.fill(nil, row.size..(column_sizes.size - 1))
      row = row.each_with_index.map { |v, i| v.to_s + ' ' * (column_sizes[i] - v.to_s.length) }
      puts '| ' + row.join(' | ') + ' |'
    end
    puts head
  end
end

def rows_stats(rows)
  {
    avg_latency: rows.map { |row| row['Latency'].to_i }.sum / rows.size,
    max_latency: rows.map { |row| row['Latency'].to_i }.max,
    avg_elapsed: rows.map { |row| row['elapsed'].to_i }.sum / rows.size,
    max_elapsed: rows.map { |row| row['elapsed'].to_i }.max,
    failure_percent: rows.filter { |row| row['success'] != 'true' }.size / rows.size
  }
end

def compare(rows, cfg)
  rows = rows.filter { |row| row['label'] == cfg[:label] }
  actual = rows_stats(rows)
  thresholds = cfg[:failure_thresholds]
  any_failure = (
    (thresholds[:avg_latency] && actual[:avg_latency] > thresholds[:avg_latency]) ||
    (thresholds[:max_latency] && actual[:max_latency] > thresholds[:max_latency]) ||
    (thresholds[:avg_elapsed] && actual[:avg_elapsed] > thresholds[:avg_elapsed]) ||
    (thresholds[:max_elapsed] && actual[:max_elapsed] > thresholds[:max_elapsed]) ||
    (thresholds[:failure_percent] && actual[:failure_percent] > thresholds[:failure_percent])
  )

  puts 'TEST FAILURE' if any_failure
  [
    [
      cfg[:label].ljust(30, ' ')
    ],
    [
      '',
      'Avg Latency',
      'Max Latency',
      'Avg Elapsed',
      'Max Elapsed',
      ' Failure % '
    ],
    [
      'Actual',
      "#{actual[:avg_latency].to_s.rjust(8, ' ')} ms",
      "#{actual[:max_latency].to_s.rjust(8, ' ')} ms",
      "#{actual[:avg_elapsed].to_s.rjust(8, ' ')} ms",
      "#{actual[:max_elapsed].to_s.rjust(8, ' ')} ms",
      "#{actual[:failure_percent].to_s.rjust(9, ' ')} %"
    ],
    [
      'Threshold',
      "#{thresholds[:avg_latency].to_s.rjust(8, ' ') || '-'} ms",
      "#{thresholds[:max_latency].to_s.rjust(8, ' ') || '-'} ms",
      "#{thresholds[:avg_elapsed].to_s.rjust(8, ' ') || '-'} ms",
      "#{thresholds[:max_elapsed].to_s.rjust(8, ' ') || '-'} ms",
      "#{thresholds[:failure_percent].to_s.rjust(9, ' ') || '-'} %"
    ]
  ].to_table

  any_failure
end

comparisons = config.map { |cfg| compare(jtl_rows, cfg) }
all_rows_stats = rows_stats(jtl_rows)
[
  [
    'ALL STATS'.ljust(30, ' ')
  ],
  [
    '',
    'Avg Latency',
    'Max Latency',
    'Avg Elapsed',
    'Max Elapsed',
    ' Failure % '
  ],
  [
    'Actual',
    "#{all_rows_stats[:avg_latency].to_s.rjust(8, ' ')} ms",
    "#{all_rows_stats[:max_latency].to_s.rjust(8, ' ')} ms",
    "#{all_rows_stats[:avg_elapsed].to_s.rjust(8, ' ')} ms",
    "#{all_rows_stats[:max_elapsed].to_s.rjust(8, ' ')} ms",
    "#{all_rows_stats[:failure_percent].to_s.rjust(9, ' ')} %"
  ]
].to_table

exit_status = comparisons.include?(true) ? 1 : 0
puts 'ONE OR MORE TESTS FAILED - SEE ABOVE OUTPUT' if exit_status == 1
exit(exit_status)
