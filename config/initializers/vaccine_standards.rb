VACCINE_STANDARDS = YAML.safe_load(File.read(Rails.root.join('config', 'vaccines.yml'))).freeze
