require 'securerandom'
require 'io/console'
require 'digest'

namespace :admin do

  desc "Import/Update Jurisdictions"
  task import_or_update_jurisdictions: :environment do
    include JurisdictionIdsAndPathsCacheInvalidator
    ActiveRecord::Base.transaction do
      config_contents = YAML.load_file('config/sara/jurisdictions.yml')

      config_contents.each do |jur_name, jur_values|
        parse_jurisdiction(nil, jur_name, jur_values)
      end

      # Call hierarchical_symptomatic_condition on each jurisdiction
      # Will pre-generate all possible thresholdConditions
      Jurisdiction.all.each do |jur|
        jur.hierarchical_symptomatic_condition
      end

      # Seed newly created jurisdictions with (empty) analytic cache entries
      Rake::Task["analytics:cache_current_analytics"].reenable
      Rake::Task["analytics:cache_current_analytics"].invoke
      puts "\e[41mNOTICE: Make sure that this rake task has been run the exact same number of times with identical jurisdiction.yml files on the enrollment and assessment servers\e[0m"
      puts "\e[41mThe following output on each of the servers should be EXACTLY EQUAL\e[0m"
      combined_hash = ""
      Jurisdiction.all.each do |jur|
        theshold_conditions_edit_count = 0
        jur.path&.map(&:threshold_conditions)&.each { |x| theshold_conditions_edit_count += x.count }
        puts jur.jurisdiction_path_string.ljust(80)  + "Edits: " + theshold_conditions_edit_count.to_s.ljust(5) + "Hash: " + jur.jurisdiction_path_threshold_hash[0..6]
        combined_hash += jur.jurisdiction_path_threshold_hash
      end

      JurisdictionIdsAndPathsCacheInvalidator.invalidate

      unique_identifier_check = if Jurisdiction.where(unique_identifier: nil).count.zero?
                                  "\e[42mChecking Jurisdictions for nil unique identifiers... no nil unique identifiers found, no further action is needed.\e[0m"
                                else
                                  "\e[41mChecking Jurisdictions for nil unique identifiers... nil unique identifiers found! This should be investigated as soon as possible.\e[0m"
                                end
      puts unique_identifier_check

      final_hash = Digest::SHA256.hexdigest(combined_hash)
      puts "\e[41mCompare the following hash as output by this task when run on the enrollment and assessment servers and make sure that the hashes are EXACTLY EQUAL\e[0m"
      puts "\e[41m>>>>>>>>>>#{final_hash}<<<<<<<<<<\e[0m"
      puts "Do the hashes on the enrollment and assessment servers match? (y/N)"
      res = STDIN.getc
      exit unless res.downcase == 'y'
    end
  end

  # This is useful in case the base/sample jurisdiction.yml is run on prod and the jurisdictions with generic names need to be removed
  # Example Usage: rake admin:delete_jurisdiction_with_id ID=3
  desc "Delete Jurisdiction"
  task delete_jurisdiction_with_id: :environment do
    include JurisdictionIdsAndPathsCacheInvalidator
    jur_id = ENV['ID']
    unless Jurisdiction.exists?(jur_id)
      puts "Error: Jurisdiction with id #{jur_id} not found"
      exit
    end
    jur = Jurisdiction.find(jur_id)
    jur_name = jur.name
    if !jur.children.count.zero?
      puts "Error: Will not delete jurisdiction that has child jurisdictions. Delete #{jur.children.pluck(:name).to_s} first"
      exit
    end
    patient_count = Patient.where(jurisdiction_id: jur_id).count
    if !patient_count.zero?
      puts "Error: Will not delete jurisdiction that has patients in it. #{jur_name} has #{patient_count} patients in it"
      exit
    end
    user_count = User.where(jurisdiction_id: jur_id).count
    if !user_count.zero?
      puts "Error: Will not delete jurisdiction that has users in it. #{jur_name} has #{user_count} users in it"
      exit
    end
    threshold_conditions_count = ThresholdCondition.where(jurisdiction_id: jur_id).count
    analytic_count = Analytic.where(jurisdiction_id: jur_id).count
    puts "In addition to deleting jurisdiction #{jur_name} the following associated records will be deleted"
    puts "#{patient_count} Patients will be deleted"
    puts "#{user_count} Users will be deleted"
    puts "#{threshold_conditions_count} ThresholdCondition will be deleted"
    puts "#{analytic_count} Analytic will be deleted"
    puts "Are you sure you want to proceed? [Y/y] to continue"
    res = STDIN.getc
    exit unless res.downcase == 'y'
    ActiveRecord::Base.transaction do
      ThresholdCondition.where(jurisdiction_id: jur_id).delete_all
      Analytic.where(jurisdiction_id: jur_id).delete_all
      jur.delete
    end
    JurisdictionIdsAndPathsCacheInvalidator.invalidate
    rescue ActiveRecord::RecordInvalid
      puts "Jurisdiction transfer failed"
    puts "Complete"
  end

  def parse_jurisdiction(parent, jur_name, jur_values)
    jurisdiction = nil
    matching_jurisdictions = Jurisdiction.where(name: jur_name)
    matching_jurisdictions.each do |matching_jurisdiction|
      # Also works for the case where parent is nil ie: top-level jurisdiction
      if matching_jurisdiction.parent&.path == parent&.path
        jurisdiction = matching_jurisdiction
        break
      end
    end
    # Create jurisdiction for it does not already exist
    if jurisdiction == nil
      jurisdiction = Jurisdiction.create(name: jur_name , parent: parent)
      unique_identifier = Digest::SHA256.hexdigest(jurisdiction.jurisdiction_path_string)
      jurisdiction.update(unique_identifier: unique_identifier, path: jurisdiction.jurisdiction_path_string)
    end

    # Parse and add symptoms list to jurisdiction if included
    jur_symps = nil
    if jur_values != nil
      jur_symps = jur_values['symptoms']
      jurisdiction.email = jur_values['email'] || ''
      jurisdiction.phone = jur_values['phone'] || ''
      jurisdiction.webpage = jur_values['webpage'] || ''
      jurisdiction.webpage = jur_values['message'] || ''
    end
    threshold_condition_symptoms = []
    if jur_symps != nil
      jur_symps.each do |symp_name, symp_vals|
        symptom = {"name"=>symp_name.parameterize, "label"=> symp_name}.merge(symp_vals)
        threshold_condition_symptoms.push(Symptom.new(symptom))
      end
    end

    threshold_condition = ThresholdCondition.create(symptoms: threshold_condition_symptoms)
    jurisdiction.threshold_conditions.push(threshold_condition)

    jurisdiction.save


    # Parse and recursively create children jurisdictions if  included
    children_jurs = nil
    if jur_values != nil
      children_jurs = jur_values['children']
    end
    if children_jurs != nil
      children_jurs.each do |child_jur_name, child_jur_vals|
        parse_jurisdiction(jurisdiction, child_jur_name, child_jur_vals)
      end
    end
    JurisdictionIdsAndPathsCacheInvalidator.invalidate
  end

  desc "Transfer Jurisdiction Resources To Another Jurisdiction"
  # Example Usage: rake admin:transfer_jurisdiction_resources FROM=3 TO=4
  task transfer_jurisdiction_resources: :environment do
    include include JurisdictionIdsAndPathsCacheInvalidator

    from_id = ENV['FROM']
    to_id = ENV['TO']
    from_patients = Patient.where(jurisdiction_id: from_id)
    from_users = User.where(jurisdiction_id: from_id)
    from_analytics= Analytic.where(jurisdiction_id: from_id)
    puts "#{from_patients.count} Patients will be moved"
    puts "#{from_users.count} Users will be moved"
    puts "Are you sure you want to proceed? [Y/y] to continue"
    res = STDIN.getc
    exit unless res.downcase == 'y'
    ActiveRecord::Base.transaction do
      from_patients.each do |p| p.update!(jurisdiction_id: to_id) end
      from_users.each do |u| u.update!(jurisdiction_id: to_id) end
    end
    JurisdictionIdsAndPathsCacheInvalidator.invalidate
    rescue ActiveRecord::RecordInvalid
      puts "Jurisdiction transfer failed"
  end

  desc "Create User Role Types"
  task create_roles: :environment do
    role_names = ['admin', 'analyst', 'enroller', 'public_health', 'public_health_enroller']
    role_names.each do |role_name|
      if Role.where(name: role_name).count == 0
        Role.create(name: role_name)
      end
    end
  end

  desc 'Run the purge job'
  task purge_job: :environment do
    PurgeJob.perform_later
  end
end
