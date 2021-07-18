# frozen_string_literal: true

require 'json'
require 'octokit'
require 'open-uri'
require 'zip'

if ENV['PERSONAL_TOKEN'].nil?
  puts '$PERSONAL_TOKEN must be set and token must have "workflow" permissions!'
  exit 1
end

##
# Get artifact information so that ones we are interested in can be downloaded.
#
# https://docs.github.com/en/rest/reference/actions
# https://github.com/octokit/octokit.rb/pull/1236
#
def get_artifact_info(page)
  print "\rFetching artifacts page: #{page}         "
  client = Octokit::Client.new(access_token: ENV['PERSONAL_TOKEN'], per_page: 100)
  client.get("https://api.github.com/repos/SaraAlert/SaraAlert/actions/artifacts?page=#{page}")
end

##
# Download an artifact zip to a specific path.
#
# https://docs.github.com/en/rest/reference/actions
#
def fetch_artifact_zip(download_path, url)
  # rubocop:disable Security/Open
  open(download_path, 'wb') do |file|
    file.print URI.open(url, 'Authorization' => "token #{ENV['PERSONAL_TOKEN']}").read
  end
  # rubocop:enable Security/Open
end

# https://stackoverflow.com/questions/9204423/how-to-unzip-a-file-in-ruby-on-rails
def extract_zip(file, destination)
  Zip::File.open(file) do |zip_file|
    zip_file.each do |f|
      fpath = File.join(destination, f.name)
      zip_file.extract(f, fpath) unless File.exist?(fpath)
    end
  end
end

path_prefix = 'performance/github_artifacts'
zip_folder = "#{path_prefix}/zip"
json_folder = "#{path_prefix}/json"

# Downloaded artifact zips are stored here.
FileUtils.mkdir_p(zip_folder)

# The extracted results JSON are extracted here.
FileUtils.mkdir_p(json_folder)

# These are the job names that artifact zips will be downloaded for.
interested_names = Set.new(%w[
                             send-assessments-job-benchmark
                             close-patients-job-benchmark
                             micro-benchmarks
                           ])

# Stores artifact metadata from `get_artifact_info()` for artifacts that
# we are interested in downloading.
interested_artifact_info = []

# Will stop the script from collecting more artifact metadata if the size of
# `interested_artifact_info` becomes larger than this threshold.
max_artifacts_to_download = ENV['MAX_ARTIFACTS']&.to_i || 100

# Tracks the page we want to fetch from `get_artifact_info`.
page = 1

# Tracks how many artifacts that GitHub says are available.
total_artifact_count = nil

# Tracks how many artifacts we have seen info about.
total_artifact_seen = 0

# Collection of all of the artifacts that should be downloaded.
interested_artifact_info += []

# Keep fetching artifact info until we gather enough.
# `total_artifact_count` initializes as nil and is set once
# after the first iteration.
while total_artifact_count.nil? || total_artifact_seen < total_artifact_count
  break if interested_artifact_info.size >= max_artifacts_to_download

  artifacts = get_artifact_info(page)
  total_artifact_count ||= artifacts[:total_count]
  total_artifact_seen += artifacts[:artifacts].size
  interested_artifact_info += artifacts[:artifacts].filter { |artifact| interested_names.include? artifact[:name] }

  # Increment the page number
  page += 1
end

puts 'Got all artifact info!'

# Download each interested artifact zip only if we do not have it yet.
interested_artifact_info.each_with_index do |artifact, index|
  if File.file?("#{zip_folder}/#{artifact[:id]}.zip")
    print "\r(#{index + 1}/#{interested_artifact_info.size}) Already have artifacts for job: #{artifact['id']}         "
    next
  end

  print "\r(#{index + 1}/#{interested_artifact_info.size}) Fetching artifact zip for job: #{artifact['id']}            "
  fetch_artifact_zip(
    "#{zip_folder}/#{artifact['id']}.zip",
    artifact['archive_download_url']
  )
end

puts 'Got all artifact zips!'

# Extract the artifact zips into the json folder,
# but hide all of the zip command's output.
print 'Extracting all zips'
Dir.glob("#{zip_folder}/*.zip").each { |zip_path| extract_zip(zip_path, json_folder) }
FileUtils.rm("#{json_folder}/.gitignore", force: true) # some artifacts may have a gitignore file present in them
puts 'Extracted all zips!'
