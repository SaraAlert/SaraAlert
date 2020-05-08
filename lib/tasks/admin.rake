require 'securerandom'
require 'io/console'
require 'digest'

namespace :admin do

  desc "Import/Update Jurisdictions"
  task import_or_update_jurisdictions: :environment do
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

    final_hash = Digest::SHA256.hexdigest(combined_hash)
    puts "\e[41mCompare the folliwng hash as output by this task when run on the enrollment and assessment servers and make sure that the hashes are EXACTLY EQUAL\e[0m"
    puts "\e[41m>>>>>>>>>>#{final_hash}<<<<<<<<<<\e[0m"
  end

  # This is useful in case the base/sample jurisdiction.yml is run on prod and the jurisdictions with generic names need to be removed
  # Example Usage: rake admin:delete_jurisdiction_with_name NAME='County 3'
  desc "Delete Jurisdiction"
  task delete_jurisdiction_with_name: :environment do
    jur_name = ENV['NAME']
    if Jurisdiction.where(name: jur_name).count.zero?
      puts "Error: Jurisdiction with name #{jur_name} not found"
      exit
    elsif Jurisdiction.where(name: jur_name).count != 1
      puts "Error: Multiple jurisdiction with name #{jur_name} found"
      exit
    end
    jur_id = Jurisdiction.where(name: jur_name).first.id
    jur = Jurisdiction.find(jur_id)
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
    transfers_count = Transfer.where(to_jurisdiction_id: jur_id).count + Transfer.where(from_jurisdiction_id: jur_id).count
    puts "In addition to deleting jurisdiction #{jur_name} the following associated records will be deleted"
    puts "#{patient_count} Patients will be deleted"
    puts "#{user_count} Users will be deleted"
    puts "#{threshold_conditions_count} ThresholdCondition will be deleted"
    puts "#{analytic_count} Analytic will be deleted"
    puts "#{transfers_count} Transfer objects will be deleted"
    puts "Are you sure you want to proceed? [Y/y] to continue"
    res = STDIN.getc
    exit unless res.downcase == 'y'
    puts "Failed to Delete ThresholdConditions" unless ThresholdCondition.where(jurisdiction_id: jur_id).delete_all
    puts "Failed to Delete Analytics" unless Analytic.where(jurisdiction_id: jur_id).delete_all
    puts "Failed to Delete Transfers" unless Transfer.where(to_jurisdiction_id: jur_id).delete_all
    puts "Failed to Delete Transfers" unless Transfer.where(from_jurisdiction_id: jur_id).delete_all
    puts "Failed to Delete Jurisdiction" unless jur.delete
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

end
