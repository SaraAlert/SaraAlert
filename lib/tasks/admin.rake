namespace :admin do

    desc "Import/Update Jurisdictions"
    task import_or_update_jurisdictions: :environment do
        config_contents = YAML.load_file('config/sara/jurisdictions.yml')
        
        config_contents.each do |jur_name, jur_values|
            parse_jurisdiction(nil, jur_name, jur_values)
        end
    end

    def parse_jurisdiction(parent, jur_name, jur_values)
        jurisdiction = nil
        matching_jurisdictions = Jurisdiction.where(name: jur_name)
        matching_jurisdictions.each do |matching_jurisdiction|
            # Also works for the case where parent is nil ie: top-level jurisdiction
            if matching_jurisdiction.parent&.name == parent&.name
                jurisdiction = matching_jurisdiction
                break
            end
        end
        # Create jurisdiction for it does not already exist
        if jurisdiction == nil
            jurisdiction = Jurisdiction.create(name: jur_name , parent: parent)
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

end