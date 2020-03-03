namespace :admin do
    
    desc "Set Symptoms List"
    task add: :environment do
        raise "This task is only for use in a development environment" unless Rails.env == 'development'

        temperature_symptom = FloatSymptom.create(label: 'Temperature', name: 'temperature', float_value: 101.4)
        cough_symptom = BoolSymptom.create(label: 'Cough', name: 'cough', bool_value: true)
        difficulty_breathing_symptom = BoolSymptom.create(label: 'Difficulty Breathing', name: 'difficulty_breathing', bool_value: true)

        usa_condition = ThresholdCondition.new(symptoms: [temperature_symptom, cough_symptom, difficulty_breathing_symptom])
        usa_condition.threshold_condition_hash = usa_condition.symptoms_hash
        usa_condition.save

        usa = Jurisdiction.where(name: 'USA').first
        usa.symptomatic_definitions.push(usa_condition)
        usa.save


        state1 = Jurisdiction.where(name: 'State 1').first
        ate_shellfish = BoolSymptom.create(label: 'Ate Shellfish', name: 'ate_shellfish', bool_value: true)
        state_condition = ThresholdCondition.create(symptoms: [ate_shellfish])
        state1.symptomatic_definitions.push(state_condition)
        state1.save

    end
end