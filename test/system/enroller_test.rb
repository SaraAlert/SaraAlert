require "application_system_test_case"

require_relative "components/monitoree_enrollment/form"

class EnrollerTest < ApplicationSystemTestCase

  MONITOREES = YAML.load(File.read(__dir__ + "/form_data/monitorees.yml"))
  USERS = YAML.load(File.read(__dir__ + "/../fixtures/users.yml"))

  ENROLLERS_HOME_PAGE_URL = "/patients"
  EPI_ENROLLERS_HOME_PAGE_URL = "/public_health"
  
  @@monitoree_enrollment_form = MonitoreeEnrollmentForm.new(nil)

  test "local enroller enroll monitoree" do
    @@monitoree_enrollment_form.enroll_monitoree(USERS["state1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_1"])
  end

  test "state enroller enroll monitoree with all fields" do
    @@monitoree_enrollment_form.enroll_monitoree(USERS["locals1c1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_2"])
  end

  test "local enroller enroll monitoree with only necessary fields" do
    @@monitoree_enrollment_form.enroll_monitoree(USERS["locals1c2_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_3"])
  end

  test "local enroller enroll monitoree with foreign address" do
    @@monitoree_enrollment_form.enroll_monitoree(USERS["state2_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_4"])
  end

  test "epi enroller enroll monitoree with all races and exposure risks" do
    ## Uncomment when bug is fixed where epi enroller can't view patient they just enrolled
    # @@monitoree_enrollment_form.enroll_monitoree(USERS["state1_epi_enroller"], EPI_ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_5"])
    @@monitoree_enrollment_form.enroll_monitoree(USERS["locals1c1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_5"])
  end

  test "local enroller add group member after enrolling monitoree with international additional planned travel" do
    @@monitoree_enrollment_form.enroll_monitorees_in_group(USERS["locals2c3_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_6"], MONITOREES["monitoree_7"])
  end

  test "epi enroller add group member after enrolling monitoree with domestic additional planned travel" do
    ## Uncomment when bug is fixed where epi enroller can't view patient they just enrolled
    # @@monitoree_enrollment_form.enroll_monitorees_in_group(USERS["state1_epi_enroller"], EPI_ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_2"], MONITOREES["monitoree_8"])
    @@monitoree_enrollment_form.enroll_monitorees_in_group(USERS["state1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_2"], MONITOREES["monitoree_8"])
  end

  test "local enroller add group member after enrolling monitoree with foreign address" do
    @@monitoree_enrollment_form.enroll_monitorees_in_group(USERS["locals2c4_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_4"], MONITOREES["monitoree_9"])
  end

  test "copy home address to monitored address when set to home address button is clicked" do
    @@monitoree_enrollment_form.enroll_monitoree_with_same_monitored_address_as_home(USERS["state2_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_10"])
  end

  test "input validation" do
    @@monitoree_enrollment_form.verify_enrollment_input_validation(USERS["state2_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_11"])
  end

  test "preserve form data between different sections if next or previous are clicked" do
    @@monitoree_enrollment_form.verify_form_data_after_navigation(USERS["locals2c3_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_12"])
  end

  test "edit data on the review page" do
    @@monitoree_enrollment_form.enroll_monitoree_and_edit_data_on_review_page(USERS["state1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_11"], MONITOREES["monitoree_12"])
  end

  test "edit existing data" do
    ## Uncoment when bug is fixed where info edited from one section does not persist after editing info from another
    # @@monitoree_enrollment_form.enroll_monitoree_and_edit_info(USERS["locals1c1_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_3"], MONITOREES["monitoree_6"])
  end

  test "cancel monitoree enrollment via cancel button" do
    @@monitoree_enrollment_form.enroll_monitoree_and_cancel(USERS["locals2c3_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_10"], "Cancel")
  end

  test "cancel monitoree enrollment via return to dashboard link" do
    @@monitoree_enrollment_form.enroll_monitoree_and_cancel(USERS["locals2c4_enroller"], ENROLLERS_HOME_PAGE_URL, MONITOREES["monitoree_1"], "Return To Dashboard")
  end

end
