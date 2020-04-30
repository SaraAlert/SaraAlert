require 'rake'
load 'lib/tasks/admin.rake'
class AdminTaskTest < ActiveSupport::TestCase

  def setup
    # Clean up any existing records out of test database
    Jurisdiction.delete_all
    Assessment.delete_all
    Symptom.delete_all
    Condition.delete_all
    Patient.delete_all
  end

  def identical_arrays(ar1, ar2)
    if ar1.difference(ar2) != []
      return false
    end
    return true
  end

  test "jurisdiction and symptom creation and editing" do
    # The JSON representation of a config/sara/jurisdiction.yml file
    # this is how the config file is represented after it is parsed out of .yml
    baseline_jurisdictions = {"USA"=>{"symptoms"=>{"Fever"=>{"value"=>true, "type"=>"BoolSymptom"}, "Cough"=>{"value"=>true, "type"=>"BoolSymptom"}, "Difficulty Breathing"=>{"value"=>true, "type"=>"BoolSymptom"}}, "children"=>{"State 1"=>{"children"=>{"County 1"=>nil, "County 2"=>nil}}, "State 2"=>{"children"=>{"County 3"=>nil, "County 4"=>nil}}}}}
    parse_jurisdiction(nil, 'USA', baseline_jurisdictions['USA'])

    # Assert Jurisdictions have all been loaded and hierarchy is correct
    assert_equal(Jurisdiction.all.pluck(:name), ["USA", "State 1", "County 1", "County 2", "State 2", "County 3", "County 4"])
    assert_equal(Jurisdiction.where(name: 'County 4').first[:path], "USA, State 2, County 4")
    # Assert ThresholdConditions have been saved for each jurisdiction
    assert_equal(Jurisdiction.count, ThresholdCondition.count)
  
    # Assert USA is the only jurisdiction with a populated threshold_condition symptoms list
    assert_equal(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.length, 3)
    assert_equal(Jurisdiction.where(name: 'State 1').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'State 2').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 1').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 2').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 3').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 4').first.threshold_conditions.last.symptoms.length, 0)
    # Assert contents of USA symptoms list are correct
    assert(identical_arrays(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.name}, ["fever", "cough", "difficulty-breathing"]))
    assert(identical_arrays(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Difficulty Breathing"]))

    assert_equal(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.value}, [true, true, true])
    # Test hierarchical_symptomatic_condition which will generate the hierarchical threshold conditions
    usa_hierarchical_threshold_condition = Jurisdiction.where(name: 'USA').first.hierarchical_symptomatic_condition
    # Assert that a new threshold condition was created
    assert_equal(Jurisdiction.count + 1, ThresholdCondition.count)
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "difficulty-breathing"]))
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Difficulty Breathing"]))
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.value},  [true, true, true])) 
  
    # Re-retrieve hierarchical_symptomatic_condition and sssert that a new threshold condition was NOT created since a ThresholdCondition with the same hash should already exist
    usa_hierarchical_threshold_condition = Jurisdiction.where(name: 'USA').first.hierarchical_symptomatic_condition
    assert_equal(Jurisdiction.count + 1, ThresholdCondition.count)

    # Test the hierarchical_condition_unpopulated_symptoms returned by the jurisdiction, this is an unpopulated version of the threshold condition ie: the condition to be filled out
    usa_hierarchical_unpopulated_symptoms_condition = Jurisdiction.where(name: 'USA').first.hierarchical_condition_unpopulated_symptoms
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "difficulty-breathing"]))
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Difficulty Breathing"]))
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.value}, [nil, nil, nil])) 
    # Make sure that the unpopulated_symptoms_condition references the correct threshold condition
    assert_equal(usa_hierarchical_threshold_condition.threshold_condition_hash, usa_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash)

    # Test hierarchical_symptomatic_condition which will generate the hierarchical threshold conditions
    county4_hierarchical_threshold_condition = Jurisdiction.where(name: 'County 4').first.hierarchical_symptomatic_condition
    # Assert that a new threshold condition was created
    assert_equal(Jurisdiction.count + 2, ThresholdCondition.count)
    assert(identical_arrays(county4_hierarchical_threshold_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "difficulty-breathing"]))
    assert(identical_arrays(county4_hierarchical_threshold_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Difficulty Breathing"]))
    assert(identical_arrays(county4_hierarchical_threshold_condition.symptoms.collect{|x| x.value}, [true, true, true]))
    # Re-retrieve hierarchical_symptomatic_condition and sssert that a new threshold condition was NOT created since a ThresholdCondition with the same hash should already exist
    county4_hierarchical_threshold_condition = Jurisdiction.where(name: 'County 4').first.hierarchical_symptomatic_condition
    assert_equal(Jurisdiction.count + 2, ThresholdCondition.count)

    # Test the hierarchical_condition_unpopulated_symptoms returned by the jurisdiction, this is an unpopulated version of the threshold condition ie: the condition to be filled out
    county4_hierarchical_unpopulated_symptoms_condition = Jurisdiction.where(name: 'County 4').first.hierarchical_condition_unpopulated_symptoms
    assert(identical_arrays(county4_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "difficulty-breathing"]))
    assert(identical_arrays(county4_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Difficulty Breathing"]))
    assert(identical_arrays(county4_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.value}, [nil, nil, nil]))
    # Make sure that the unpopulated_symptoms_condition references the correct threshold condition
    assert_equal(county4_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash, county4_hierarchical_threshold_condition.threshold_condition_hash)
    # Make sure hashes for the hierarchical threshold conditions for different jurisdictions are different
    assert_not_equal(county4_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash, usa_hierarchical_threshold_condition.threshold_condition_hash)


    ########################
    ### Update Symptoms ####
    ########################
    updated_jurisdictions = {"USA"=>{"symptoms"=>{"Fever"=>{"value"=>true, "type"=>"BoolSymptom"}, "Cough"=>{"value"=>true, "type"=>"BoolSymptom"}}, "children"=>{"State 1"=>{"symptoms"=>{"Vomit"=>{"value"=>true, "type"=>"BoolSymptom"}}, "children"=>{"County 1"=>nil, "County 2"=>nil}}, "State 2"=>{"children"=>{"County 3"=>nil, "County 4"=>nil}}}}}
  
    parse_jurisdiction(nil, 'USA', updated_jurisdictions['USA'])
    # Assert Jurisdictions have all been loaded and hierarchy is correct
    assert_equal(Jurisdiction.all.pluck(:name), ["USA", "State 1", "County 1", "County 2", "State 2", "County 3", "County 4"])
    assert_equal(Jurisdiction.where(name: 'County 4').first[:path], "USA, State 2, County 4")
    # Assert that no new jurisdictions have been added
    assert_equal(Jurisdiction.count, 7)
  
    # Assert USA is the only jurisdiction with a populated threshold_condition symptoms list
    assert_equal(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.length, 2)
    assert_equal(Jurisdiction.where(name: 'State 1').first.threshold_conditions.last.symptoms.length, 1)
    assert_equal(Jurisdiction.where(name: 'State 2').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 1').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 2').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 3').first.threshold_conditions.last.symptoms.length, 0)
    assert_equal(Jurisdiction.where(name: 'County 4').first.threshold_conditions.last.symptoms.length, 0)
    # Assert contents of USA symptoms list are correct
    assert(identical_arrays(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.name}, ["fever", "cough"]))
    assert(identical_arrays(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.label}, ["Fever", "Cough"]))

    assert_equal(Jurisdiction.where(name: 'USA').first.threshold_conditions.last.symptoms.collect{|x| x.value}, [true, true])
    # Test hierarchical_symptomatic_condition which will generate the hierarchical threshold conditions
    usa_hierarchical_threshold_condition = Jurisdiction.where(name: 'USA').first.hierarchical_symptomatic_condition
    
    # Assert that a new threshold condition was created for each jurisdiction (+3 is 1 for the one we just made and 2 that were made in the first half of the test)
    assert_equal((Jurisdiction.count * 2) + 3, ThresholdCondition.count)
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.name}, ["fever", "cough"]))
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough"]))
    assert(identical_arrays(usa_hierarchical_threshold_condition.symptoms.collect{|x| x.value},  [true, true])) 
  
    # Re-retrieve hierarchical_symptomatic_condition and sssert that a new threshold condition was NOT created since a ThresholdCondition with the same hash should already exist
    usa_hierarchical_threshold_condition = Jurisdiction.where(name: 'USA').first.hierarchical_symptomatic_condition
    assert_equal((Jurisdiction.count * 2) + 3, ThresholdCondition.count)

    # Test the hierarchical_condition_unpopulated_symptoms returned by the jurisdiction, this is an unpopulated version of the threshold condition ie: the condition to be filled out
    usa_hierarchical_unpopulated_symptoms_condition = Jurisdiction.where(name: 'USA').first.hierarchical_condition_unpopulated_symptoms
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.name}, ["fever", "cough"]))
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough"]))
    assert(identical_arrays(usa_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.value}, [nil, nil])) 
    # Make sure that the unpopulated_symptoms_condition references the correct threshold condition
    assert_equal(usa_hierarchical_threshold_condition.threshold_condition_hash, usa_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash)

    # Test hierarchical_symptomatic_condition which will generate the hierarchical threshold conditions
    county2_hierarchical_threshold_condition = Jurisdiction.where(name: 'County 2').first.hierarchical_symptomatic_condition
    # Assert that a new threshold condition was created
    assert_equal((Jurisdiction.count * 2) + 4, ThresholdCondition.count)
    assert(identical_arrays(county2_hierarchical_threshold_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "vomit"]))
    assert(identical_arrays(county2_hierarchical_threshold_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Vomit"]))
    assert(identical_arrays(county2_hierarchical_threshold_condition.symptoms.collect{|x| x.value}, [true, true, true]))
    # Re-retrieve hierarchical_symptomatic_condition and sssert that a new threshold condition was NOT created since a ThresholdCondition with the same hash should already exist
    county2_hierarchical_threshold_condition = Jurisdiction.where(name: 'County 2').first.hierarchical_symptomatic_condition
    assert_equal((Jurisdiction.count * 2) + 4, ThresholdCondition.count)

    # Test the hierarchical_condition_unpopulated_symptoms returned by the jurisdiction, this is an unpopulated version of the threshold condition ie: the condition to be filled out
    county2_hierarchical_unpopulated_symptoms_condition = Jurisdiction.where(name: 'County 2').first.hierarchical_condition_unpopulated_symptoms
    assert(identical_arrays(county2_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.name}, ["fever", "cough", "vomit"]))
    assert(identical_arrays(county2_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.label}, ["Fever", "Cough", "Vomit"]))
    assert(identical_arrays(county2_hierarchical_unpopulated_symptoms_condition.symptoms.collect{|x| x.value}, [nil, nil, nil]))
    # Make sure that the unpopulated_symptoms_condition references the correct threshold condition
    assert_equal(county2_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash, county2_hierarchical_threshold_condition.threshold_condition_hash)
    # Make sure hashes for the hierarchical threshold conditions for different jurisdictions are different
    assert_not_equal(county2_hierarchical_unpopulated_symptoms_condition.threshold_condition_hash, usa_hierarchical_threshold_condition.threshold_condition_hash)
  end

end