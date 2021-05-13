# frozen_string_literal: true

require 'json'
require 'caxlsx'
require 'fast_excel'
require 'byebug'

# Common variables
path_prefix = 'performance/github_artifacts'
json_folder = "#{path_prefix}/json"
xlsx_folder = "#{path_prefix}/xlsx"

# Ensure folders exist
`mkdir -p #{json_folder}`
`mkdir -p #{xlsx_folder}`

# Find all JSON files
json_files = `ls #{json_folder}`.split("\n").map { |p| "#{json_folder}/#{p}" }

# Parse all JSON contents
all_json_contents = json_files.map { |json_path| JSON.parse(File.read(json_path)) }

# Group all JSON by the test name
grouped_benchmarks = all_json_contents.group_by { |json| json['name'] }

# The columns that we expect in every result JSON
data_columns = %w[
  name
  branch
  duration
  threshold
  passed
  stackprof_enabled
  memprof_enabled
  created_at
]

# https://github.com/caxlsx/caxlsx/blob/master/docs/style_reference.md
data_column_widths = [
  35, # name
  35, # branch
  18, # duration
  10, # threshold
  10, # passed
  18, # stackprof_enabled
  18, # memprof_enabled
  30 # created_at
]

# Write all data to an excel file
# caxlsx was writing invalid workbooks for an unknown reason when writing data.
xlsx_file = "#{xlsx_folder}/GitHub_Actions_Performance_Data_#{Time.now.to_i}.xlsx"
workbook = FastExcel.open(xlsx_file, constant_memory: true)
workbook.default_format.set(
  font_size: 12,
  font_family: 'Courier',
  align: { h: :align_center, v: :align_vertical_center }
)

grouped_benchmarks.each do |group_name, group|
  worksheet = workbook.add_worksheet(group_name)
  worksheet.append_row data_columns
  data_column_widths.each_with_index { |width, col| worksheet.set_column_width(col, width) }
  group.each do |json|
    row = [
      json['name'],
      json['branch'],
      json['duration'].truncate(7),
      json['threshold'],
      json['passed'],
      json['stackprof_enabled'],
      json['memprof_enabled'],
      json['created_at']
    ]
    worksheet.append_row row
  end
end
workbook.close

puts "All data written to #{xlsx_file}"
