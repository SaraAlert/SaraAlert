# frozen_string_literal: true

require 'json'

if ENV['PERSONAL_TOKEN'].nil?
  puts '$PERSONAL_TOKEN must be set and token must have "workflow" permissions!'
  exit 1
end

##
# Get artifact information so that ones we are interested in can be downloaded.
#
# https://docs.github.com/en/rest/reference/actions
#
def get_artifact_info(page)
  print "\rFetching artifacts page: #{page}         "
  artifacts = `curl -s \
    -H "Authorization: token $PERSONAL_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/SaraAlert/SaraAlert/actions/artifacts?page=#{page}`
  JSON.parse(artifacts)
end

##
# Download an artifact zip to a specific path.
#
# https://docs.github.com/en/rest/reference/actions
#
def fetch_artifact_zip(download_path, url)
  `curl \
    -sLJo #{download_path} \
    -H "Authorization: token $PERSONAL_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H 'Accept: application/octet-stream' \
    #{url}`
end

path_prefix = 'performance/github_artifacts'

# Downloaded artifact zips are stored here.
`mkdir -p #{path_prefix}/zip`
# The extracted results JSON are extracted here.
`mkdir -p #{path_prefix}/json`

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
max_artifacts_to_download = 100

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
  total_artifact_count ||= artifacts['total_count']
  total_artifact_seen += artifacts['artifacts'].size
  interested_artifact_info += artifacts['artifacts'].filter { |artifact| interested_names.include? artifact['name'] }

  # Increment the page number
  page += 1
end

puts 'Got all artifact info!'

# Download each interested artifact zip only if we do not have it yet.
interested_artifact_info.each_with_index do |artifact, index|
  if File.file?("#{path_prefix}/zip/#{artifact['id']}.zip")
    print "\r(#{index + 1}/#{interested_artifact_info.size}) Already have artifacts for job: #{artifact['id']}         "
    next
  end

  print "\r(#{index + 1}/#{interested_artifact_info.size}) Fetching artifact zip for job: #{artifact['id']}            "
  fetch_artifact_zip(
    "#{path_prefix}/zip/#{artifact['id']}.zip",
    artifact['archive_download_url']
  )
end

puts 'Got all artifact zips!'

# Extract the artifact zips into the json folder,
# but hide all of the zip command's output.
print 'Extracting all zips'
`unzip -qq -o #{path_prefix}/zip/\\*.zip -d #{path_prefix}/json &> /dev/null`
`rm -f #{path_prefix}/json/.gitignore` # some artifacts may have a gitignore file present in them
puts 'Extracted all zips!'
