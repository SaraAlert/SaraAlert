require "application_system_test_case"

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase
  
  TAB_SELECTION_DELAY = 0.5
  
  def verify_patients_under_tab(tab, patients, patient_ids)
    click_on tab
    patients.each do |patient_id, patient|
      search_for_and_verify_patient(patient, patient_ids.include?(patient["id"]))
    end
  end

  def verify_patient_under_tab(tab, patient)
    click_on tab
    search_for_and_verify_patient(patient, true)
  end

  def search_for_and_verify_patient(patient, should_exist)
    search_for_patient(patient)
    if should_exist
      assert_selector "td", text: get_patient_display_name(patient)
      assert_selector "td", text: patient["date_of_birth"]
    else
      refute_selector "td", text: get_patient_display_name(patient)
      refute_selector "td", text: patient["date_of_birth"]
    end
  end

  def search_for_and_view_patient(tab, patient)
    click_on tab
    search_for_patient(patient)
    click_on get_patient_display_name(patient)
  end

  def search_for_patient(patient)
    fill_in "Search:", with: patient["first_name"] + " " + patient["last_name"] + " " + patient["date_of_birth"]
  end

  def get_patient_display_name(patient)
    patient["last_name"] + ", " + patient["first_name"]
  end

  def return_to_dashboard
    click_on "Return To Dashboard"
  end

end