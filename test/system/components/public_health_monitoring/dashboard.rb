require "application_system_test_case"

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase
  
  TAB_SELECTION_DELAY = 0.5
  
  def view_patient(patient)
    search_and_verify_patient_info(patient)
    click_on(patient["last_name"] + ", " + patient["first_name"])
  end

  def search_and_verify_patient_info(patient)
    search_for_patient(patient)
    assert_selector "td", text: patient["last_name"] + ", " + patient["first_name"]
    assert_selector "td", text: patient["date_of_birth"]
  end

  def search_for_patient(patient)
    fill_in "Search:", with: patient["first_name"] + " " + patient["last_name"] + " " + patient["date_of_birth"]
  end

  def select_tab(tab)
    click_on tab
    sleep(inspection_time = TAB_SELECTION_DELAY)
  end

end