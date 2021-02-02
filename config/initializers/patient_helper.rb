PATIENT_HELPER_FILES = {
    state_names: YAML.safe_load(File.read('lib/assets/state_names.yml'), [Symbol]),
    states_with_time_zone_data: YAML.safe_load(File.read('lib/assets/states_with_time_zone_data.yml'), [Symbol]),
    languages: YAML.safe_load(File.read('lib/assets/languages.yml'), [Symbol])
}
