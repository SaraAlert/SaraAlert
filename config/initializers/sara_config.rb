ADMIN_OPTIONS = YAML.load(ERB.new(File.read("#{Rails.root.to_s}/config/sara/sara.yml")).result)
ActiveRecordWhereAssoc.default_options[:ignore_limit] = true
