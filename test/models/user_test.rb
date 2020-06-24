# frozen_string_literal: true

require 'test_case'

class UserTest < ActiveSupport::TestCase
  def setup
    @jurisdiction = create(:jurisdiction)
  end

  def teardown; end

  test 'create user' do
    assert create(:user, jurisdiction: @jurisdiction)
    assert create(:user, created_patients_count: rand(100), jurisdiction: @jurisdiction)
  end

  test 'viewable patients' do
    # No patients, nothing to view
    user = create(:user, jurisdiction: @jurisdiction)
    assert_equal 0, user.viewable_patients.length

    num_patients = rand(100)
    user_with_patients = create(:user, created_patients_count: num_patients, jurisdiction: @jurisdiction)

    # Both users can now see patients in this jurisdiction
    assert_equal @jurisdiction.all_patients, user.viewable_patients
    assert_equal @jurisdiction.all_patients, user_with_patients.viewable_patients
  end

  test 'enrolled patients' do
    num_patients = rand(100)
    user = create(:user, jurisdiction: @jurisdiction)
    user_with_patients_1 = create(:user, created_patients_count: num_patients, jurisdiction: @jurisdiction)

    # This user has not enrolled any patients
    assert_equal 0, user.enrolled_patients.length
    # All the patients in this jurisdiction have been enrolled by this user
    assert_equal @jurisdiction.all_patients, user_with_patients_1.enrolled_patients

    # Confirm that patient ownership is not overlapping
    user_with_patients_2 = create(:user, created_patients_count: num_patients, jurisdiction: @jurisdiction)
    difference = @jurisdiction.all_patients - user_with_patients_1.enrolled_patients
    assert_equal difference, user_with_patients_2.enrolled_patients
  end

  test 'get patient' do
    user_outside_jurisdiction = create(:user)
    admin = create(:admin_user)
    # User with no role and no patients in the jurisdiction
    user = create(:user, jurisdiction: @jurisdiction)
    assert_nil user.get_patient(1)

    # User with patients but no role
    user_with_patients = create(:user, created_patients_count: rand(100), jurisdiction: @jurisdiction)
    patient = user_with_patients.enrolled_patients.first
    assert_nil user_with_patients.get_patient(patient.id)

    # Enroller with no patients
    user.add_role(:enroller)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user.get_patient(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user.remove_role(:enroller)

    # Enroller with patients
    user_with_patients.add_role(:enroller)
    assert_equal patient, user_with_patients.get_patient(patient.id)
    user_with_patients.remove_role(:enroller)

    # Public health with no patients, but in the jurisdiction
    user.add_role(:public_health)
    assert_equal patient, user.get_patient(patient.id)
    user.remove_role(:public_health)

    # Public health with patients and in the jurisdiction
    user_with_patients.add_role(:public_health)
    assert_equal patient, user_with_patients.get_patient(patient.id)
    user_with_patients.remove_role(:public_health)

    # Public health outisde of jurisdiction
    user_outside_jurisdiction.add_role(:public_health)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patient(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")

    user_outside_jurisdiction.remove_role(:public_health)

    # Public health enroller with no patients (|| viewable_patients.find)
    user.add_role(:public_health_enroller)
    assert_equal patient, user.get_patient(patient.id)
    user.remove_role(:public_health_enroller)

    # Public health enroller with patients (enrolled_patients.find)
    user_with_patients.add_role(:public_health_enroller)
    assert_equal patient, user_with_patients.get_patient(patient.id)
    user_with_patients.remove_role(:public_health_enroller)

    # Public health enroller outside of jurisdiction
    user_outside_jurisdiction.add_role(:public_health_enroller)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patient(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user_outside_jurisdiction.remove_role(:public_health_enroller)

    # Admin outside of jurisdiction
    assert_nil admin.get_patient(patient.id)
    # Admin inside jurisdiction
    admin.update(jurisdiction: @jurisdiction)
    assert_nil admin.get_patient(patient.id)
  end

  test 'jurisdiction path' do
    # Top Level, no ancestors
    user = create(:user, jurisdiction: @jurisdiction)
    assert_equal @jurisdiction.name, user.jurisdiction_path.first

    # Is an Ancestor
    @jurisdiction.update(ancestry: "#{create(:jurisdiction).id}/#{@jurisdiction.id}")
    assert_equal @jurisdiction.name, user.jurisdiction_path.first
    assert_equal @jurisdiction.path.second.name, user.jurisdiction_path.last

    # Top level with ancestors
    @jurisdiction.update(ancestry: nil)
    create(:jurisdiction, parent: @jurisdiction)
    assert_equal @jurisdiction.name, user.jurisdiction_path.first
  end

  test 'user as json' do
    user = create(:user)
    assert_includes user.to_json, 'jurisdiction_path'
    assert_includes user.to_json, user.jurisdiction_path.to_s
  end

  test 'can create patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_create_patient?
    assert_not public_health.can_create_patient?
    assert enroller.can_create_patient?
    assert public_health_enroller.can_create_patient?
    assert_not analyst.can_create_patient?
  end

  test 'can view patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_patient?
    assert public_health.can_view_patient?
    assert enroller.can_view_patient?
    assert public_health_enroller.can_view_patient?
    assert_not analyst.can_view_patient?
  end

  test 'can export' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_export?
    assert public_health.can_export?
    assert_not enroller.can_export?
    assert public_health_enroller.can_export?
    assert_not analyst.can_export?
  end

  test 'can import' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_import?
    assert public_health.can_import?
    assert_not enroller.can_import?
    assert public_health_enroller.can_import?
    assert_not analyst.can_import?
  end

  test 'can edit patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_edit_patient?
    assert public_health.can_edit_patient?
    assert enroller.can_edit_patient?
    assert public_health_enroller.can_edit_patient?
    assert_not analyst.can_edit_patient?
  end

  test 'can view patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_patient_laboratories?
    assert public_health.can_view_patient_laboratories?
    assert_not enroller.can_view_patient_laboratories?
    assert public_health_enroller.can_view_patient_laboratories?
    assert_not analyst.can_view_patient_laboratories?
  end

  test 'can edit patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_edit_patient_laboratories?
    assert public_health.can_edit_patient_laboratories?
    assert_not enroller.can_edit_patient_laboratories?
    assert public_health_enroller.can_edit_patient_laboratories?
    assert_not analyst.can_edit_patient_laboratories?
  end

  test 'can create patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_create_patient_laboratories?
    assert public_health.can_create_patient_laboratories?
    assert_not enroller.can_create_patient_laboratories?
    assert public_health_enroller.can_create_patient_laboratories?
    assert_not analyst.can_create_patient_laboratories?
  end

  test 'can view patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_patient_assessments?
    assert public_health.can_view_patient_assessments?
    assert_not enroller.can_view_patient_assessments?
    assert public_health_enroller.can_view_patient_assessments?
    assert_not analyst.can_view_patient_assessments?
  end

  test 'can edit patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_edit_patient_assessments?
    assert public_health.can_edit_patient_assessments?
    assert_not enroller.can_edit_patient_assessments?
    assert public_health_enroller.can_edit_patient_assessments?
    assert_not analyst.can_edit_patient_assessments?
  end

  test 'can create patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_create_patient_assessments?
    assert public_health.can_create_patient_assessments?
    assert_not enroller.can_create_patient_assessments?
    assert public_health_enroller.can_create_patient_assessments?
    assert_not analyst.can_create_patient_assessments?
  end

  test 'can remind patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_remind_patient?
    assert public_health.can_remind_patient?
    assert_not enroller.can_remind_patient?
    assert public_health_enroller.can_remind_patient?
    assert_not analyst.can_remind_patient?
  end

  test 'can view public health dashboard' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_public_health_dashboard?
    assert public_health.can_view_public_health_dashboard?
    assert_not enroller.can_view_public_health_dashboard?
    assert public_health_enroller.can_view_public_health_dashboard?
    assert_not analyst.can_view_public_health_dashboard?
  end

  test 'can view enroller dashboard' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_enroller_dashboard?
    assert_not public_health.can_view_enroller_dashboard?
    assert enroller.can_view_enroller_dashboard?
    assert_not public_health_enroller.can_view_enroller_dashboard?
    assert_not analyst.can_view_enroller_dashboard?
  end

  test 'can view analytics' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_view_analytics?
    assert public_health.can_view_analytics?
    assert enroller.can_view_analytics?
    assert public_health_enroller.can_view_analytics?
    assert analyst.can_view_analytics?
  end

  test 'can modify subject status' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_modify_subject_status?
    assert public_health.can_modify_subject_status?
    assert_not enroller.can_modify_subject_status?
    assert public_health_enroller.can_modify_subject_status?
    assert_not analyst.can_modify_subject_status?
  end

  test 'can create subject history' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert_not admin.can_create_subject_history?
    assert public_health.can_create_subject_history?
    assert_not enroller.can_create_subject_history?
    assert public_health_enroller.can_create_subject_history?
    assert_not analyst.can_create_subject_history?
  end

  test 'can send admin emails' do
    admin = create(:usa_admin_user)
    sub_admin = create(:non_usa_admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)

    assert admin.can_send_admin_emails?
    assert_not sub_admin.can_send_admin_emails?
    assert_not public_health.can_send_admin_emails?
    assert_not enroller.can_send_admin_emails?
    assert_not public_health_enroller.can_send_admin_emails?
    assert_not analyst.can_send_admin_emails?
  end
end
