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
    assert_equal @jurisdiction.all_patients_excluding_purged, user.viewable_patients
    assert_equal @jurisdiction.all_patients_excluding_purged, user_with_patients.viewable_patients
  end

  test 'enrolled patients' do
    num_patients = rand(100)
    user = create(:user, jurisdiction: @jurisdiction)
    user_with_patients_1 = create(:user, created_patients_count: num_patients, jurisdiction: @jurisdiction)

    # This user has not enrolled any patients
    assert_equal 0, user.enrolled_patients.length
    # All the patients in this jurisdiction have been enrolled by this user
    assert_equal @jurisdiction.all_patients_excluding_purged, user_with_patients_1.enrolled_patients

    # Confirm that patient ownership is not overlapping
    user_with_patients_2 = create(:user, created_patients_count: num_patients, jurisdiction: @jurisdiction)
    difference = @jurisdiction.all_patients_excluding_purged - user_with_patients_1.enrolled_patients
    assert_equal difference, user_with_patients_2.enrolled_patients
  end

  test 'get patient' do
    user_outside_jurisdiction = create(:user)
    admin = create(:admin_user)
    # User with no role and no patients in the jurisdiction
    user = create(:user, jurisdiction: @jurisdiction)
    assert_nil user.get_patients(1)

    # User with patients but no role
    user_with_patients = create(:user, created_patients_count: rand(1..100), jurisdiction: @jurisdiction)
    patient = user_with_patients.enrolled_patients.first
    assert_nil user_with_patients.get_patients(patient.id)

    # Enroller with no patients
    user.update(role: Roles::ENROLLER)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user.get_patients(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user.update(role: '')

    # Enroller with patients
    user_with_patients.update(role: Roles::ENROLLER)
    assert_equal patient, user_with_patients.get_patients(patient.id)
    user_with_patients.update(role: Roles::ENROLLER)

    # Public health with no patients, but in the jurisdiction
    user.update(role: Roles::PUBLIC_HEALTH)
    assert_equal patient, user.get_patients(patient.id)
    user.update(role: '')

    # Public health with patients and in the jurisdiction
    user_with_patients.update(role: Roles::PUBLIC_HEALTH)
    assert_equal patient, user_with_patients.get_patients(patient.id)
    user_with_patients.update(role: '')

    # Public health outside of jurisdiction
    user_outside_jurisdiction.update(role: Roles::PUBLIC_HEALTH)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patients(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")

    user_outside_jurisdiction.update(role: '')

    # Public health enroller with no patients (|| viewable_patients.find)
    user.update(role: Roles::PUBLIC_HEALTH_ENROLLER)
    assert_equal patient, user.get_patients(patient.id)
    user.update(role: '')

    # Public health enroller with patients (enrolled_patients.find)
    user_with_patients.update(role: Roles::PUBLIC_HEALTH_ENROLLER)
    assert_equal patient, user_with_patients.get_patients(patient.id)
    user_with_patients.update(role: '')

    # Public health enroller outside of jurisdiction
    user_outside_jurisdiction.update(role: Roles::PUBLIC_HEALTH_ENROLLER)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patients(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user_outside_jurisdiction.update(role: '')

    # Super user with no patients (|| viewable_patients.find)
    user.update(role: Roles::SUPER_USER)
    assert_equal patient, user.get_patients(patient.id)
    user.update(role: '')

    # Super user with patients (enrolled_patients.find)
    user_with_patients.update(role: Roles::SUPER_USER)
    assert_equal patient, user_with_patients.get_patients(patient.id)
    user_with_patients.update(role: '')

    # Super user outside of jurisdiction
    user_outside_jurisdiction.update(role: Roles::SUPER_USER)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patients(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user_outside_jurisdiction.update(role: '')

    # Contact Tracer with no patients (|| viewable_patients.find)
    user.update(role: Roles::CONTACT_TRACER)
    assert_equal patient, user.get_patients(patient.id)
    user.update(role: '')

    # Contact Tracer with patients (enrolled_patients.find)
    user_with_patients.update(role: Roles::CONTACT_TRACER)
    assert_equal patient, user_with_patients.get_patients(patient.id)
    user_with_patients.update(role: '')

    # Contact Tracer outside of jurisdiction
    user_outside_jurisdiction.update(role: Roles::CONTACT_TRACER)
    error = assert_raises(ActiveRecord::RecordNotFound) do
      user_outside_jurisdiction.get_patients(patient.id)
    end
    assert_includes(error.message, "Couldn't find Patient with 'id'=#{patient.id}")
    user_outside_jurisdiction.update(role: '')

    # Admin outside of jurisdiction
    assert_nil admin.get_patients(patient.id)
    # Admin inside jurisdiction
    admin.update(jurisdiction: @jurisdiction)
    assert_nil admin.get_patients(patient.id)
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
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot create patient
    assert_not admin.can_create_patient?
    assert_not public_health.can_create_patient?
    assert_not analyst.can_create_patient?

    # Can create patient
    assert enroller.can_create_patient?
    assert public_health_enroller.can_create_patient?
    assert contact_tracer_user.can_create_patient?
    assert super_user.can_create_patient?
  end

  test 'can view patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view patient
    assert_not admin.can_view_patient?
    assert_not analyst.can_view_patient?

    # Can view patient
    assert public_health.can_view_patient?
    assert enroller.can_view_patient?
    assert public_health_enroller.can_view_patient?
    assert contact_tracer_user.can_view_patient?
    assert super_user.can_view_patient?
  end

  test 'can export' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot export
    assert_not admin.can_export?
    assert_not analyst.can_export?
    assert_not enroller.can_export?
    assert_not contact_tracer_user.can_export?

    # Can export
    assert public_health.can_export?
    assert public_health_enroller.can_export?
    assert super_user.can_export?
  end

  test 'can import' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot import
    assert_not admin.can_import?
    assert_not analyst.can_import?
    assert_not enroller.can_import?
    assert_not contact_tracer_user.can_import?

    # Can import
    assert public_health.can_import?
    assert public_health_enroller.can_import?
    assert super_user.can_import?
  end

  test 'can edit patient' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot edit patient
    assert_not admin.can_edit_patient?
    assert_not analyst.can_edit_patient?

    # Can edit patient
    assert public_health.can_edit_patient?
    assert enroller.can_edit_patient?
    assert contact_tracer_user.can_edit_patient?
    assert public_health_enroller.can_edit_patient?
    assert super_user.can_edit_patient?
  end

  test 'can view patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view patient labs
    assert_not admin.can_view_patient_laboratories?
    assert_not analyst.can_view_patient_laboratories?
    assert_not enroller.can_view_patient_laboratories?

    # Can view patient labs
    assert public_health.can_view_patient_laboratories?
    assert contact_tracer_user.can_view_patient_laboratories?
    assert public_health_enroller.can_view_patient_laboratories?
    assert super_user.can_view_patient_laboratories?
  end

  test 'can edit patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot edit patient labs
    assert_not admin.can_edit_patient_laboratories?
    assert_not analyst.can_edit_patient_laboratories?
    assert_not enroller.can_edit_patient_laboratories?

    # Can edit patient labs
    assert public_health.can_edit_patient_laboratories?
    assert contact_tracer_user.can_edit_patient_laboratories?
    assert public_health_enroller.can_edit_patient_laboratories?
    assert super_user.can_edit_patient_laboratories?
  end

  test 'can create patient laboratories?' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot create patient labs
    assert_not admin.can_create_patient_laboratories?
    assert_not enroller.can_create_patient_laboratories?
    assert_not analyst.can_create_patient_laboratories?

    # Can create patient labs
    assert public_health.can_create_patient_laboratories?
    assert contact_tracer_user.can_create_patient_laboratories?
    assert public_health_enroller.can_create_patient_laboratories?
    assert super_user.can_create_patient_laboratories?
  end

  test 'can view patient close contacts' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view patient close contacts
    assert_not admin.can_view_patient_close_contacts?
    assert_not enroller.can_view_patient_close_contacts?
    assert_not analyst.can_view_patient_close_contacts?

    # Can view patient close contacts
    assert public_health.can_view_patient_close_contacts?
    assert contact_tracer_user.can_view_patient_close_contacts?
    assert public_health_enroller.can_view_patient_close_contacts?
    assert super_user.can_view_patient_close_contacts?
  end

  test 'can edit patient close contacts' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot edit patient close contacts
    assert_not admin.can_edit_patient_close_contacts?
    assert_not enroller.can_edit_patient_close_contacts?
    assert_not analyst.can_edit_patient_close_contacts?

    # Can edit patient close contacts
    assert public_health.can_edit_patient_close_contacts?
    assert contact_tracer_user.can_edit_patient_close_contacts?
    assert public_health_enroller.can_edit_patient_close_contacts?
    assert super_user.can_edit_patient_close_contacts?
  end

  test 'can create patient close contacts' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot create patient close contacts
    assert_not admin.can_create_patient_close_contacts?
    assert_not enroller.can_create_patient_close_contacts?
    assert_not analyst.can_create_patient_close_contacts?

    # Can create patient close contacts
    assert public_health.can_create_patient_close_contacts?
    assert contact_tracer_user.can_create_patient_close_contacts?
    assert public_health_enroller.can_create_patient_close_contacts?
    assert super_user.can_create_patient_close_contacts?
  end

  test 'can enroll patient close contacts' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot enroll patient close contacts
    assert_not admin.can_enroll_patient_close_contacts?
    assert_not analyst.can_enroll_patient_close_contacts?
    assert_not public_health.can_enroll_patient_close_contacts?
    assert_not enroller.can_enroll_patient_close_contacts?

    # Can enroll patient close contacts
    assert contact_tracer_user.can_enroll_patient_close_contacts?
    assert public_health_enroller.can_enroll_patient_close_contacts?
    assert super_user.can_enroll_patient_close_contacts?
  end

  test 'can view patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view patient assessments
    assert_not admin.can_view_patient_assessments?
    assert_not analyst.can_view_patient_assessments?
    assert_not enroller.can_view_patient_assessments?

    # Can view patient assessments
    assert public_health.can_view_patient_assessments?
    assert contact_tracer_user.can_view_patient_assessments?
    assert public_health_enroller.can_view_patient_assessments?
    assert super_user.can_view_patient_assessments?
  end

  test 'can edit patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot edit patient assessments
    assert_not admin.can_edit_patient_assessments?
    assert_not analyst.can_edit_patient_assessments?
    assert_not enroller.can_edit_patient_assessments?

    # Can edit patient assessments
    assert public_health.can_edit_patient_assessments?
    assert contact_tracer_user.can_edit_patient_assessments?
    assert public_health_enroller.can_edit_patient_assessments?
    assert super_user.can_edit_patient_assessments?
  end

  test 'can create patient assessments' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot create patient assessments
    assert_not admin.can_create_patient_assessments?
    assert_not analyst.can_create_patient_assessments?
    assert_not enroller.can_create_patient_assessments?

    # Can create patient assessments
    assert public_health.can_create_patient_assessments?
    assert contact_tracer_user.can_create_patient_assessments?
    assert public_health_enroller.can_create_patient_assessments?
    assert super_user.can_create_patient_assessments?
  end

  test 'can download monitoree data' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot download monitoree data
    assert_not admin.can_download_monitoree_data?
    assert_not analyst.can_download_monitoree_data?
    assert_not enroller.can_download_monitoree_data?
    assert_not contact_tracer_user.can_download_monitoree_data?

    # Can download monitoree data
    assert public_health.can_download_monitoree_data?
    assert public_health_enroller.can_download_monitoree_data?
    assert super_user.can_download_monitoree_data?
  end

  test 'can view public health dashboard' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view public health dashboard
    assert_not admin.can_view_public_health_dashboard?
    assert_not analyst.can_view_public_health_dashboard?
    assert_not enroller.can_view_public_health_dashboard?

    # Can view public health dashboard
    assert public_health.can_view_public_health_dashboard?
    assert contact_tracer_user.can_view_public_health_dashboard?
    assert public_health_enroller.can_view_public_health_dashboard?
    assert super_user.can_view_public_health_dashboard?
  end

  test 'can view enroller dashboard' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view enroller dashboard
    assert_not admin.can_view_enroller_dashboard?
    assert_not analyst.can_view_enroller_dashboard?
    assert_not public_health.can_view_enroller_dashboard?
    assert_not contact_tracer_user.can_view_enroller_dashboard?
    assert_not public_health_enroller.can_view_enroller_dashboard?
    assert_not super_user.can_view_enroller_dashboard?

    # Can view enroller dashboard
    assert enroller.can_view_enroller_dashboard?
  end

  test 'can view analytics' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view analytics
    assert_not admin.can_view_analytics?
    assert_not contact_tracer_user.can_view_analytics?

    # Can view analytics
    assert analyst.can_view_analytics?
    assert public_health.can_view_analytics?
    assert enroller.can_view_analytics?
    assert public_health_enroller.can_view_analytics?
    assert super_user.can_view_analytics?
  end

  test 'can view epi analytics' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot view analytics
    assert_not admin.can_view_epi_analytics?
    assert_not enroller.can_view_epi_analytics?
    assert_not contact_tracer_user.can_view_epi_analytics?

    # Can view analytics
    assert analyst.can_view_epi_analytics?
    assert public_health.can_view_epi_analytics?
    assert public_health_enroller.can_view_epi_analytics?
    assert super_user.can_view_epi_analytics?
  end

  test 'can modify subject status' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot modify subject status
    assert_not admin.can_modify_subject_status?
    assert_not analyst.can_modify_subject_status?
    assert_not enroller.can_modify_subject_status?

    # Can modify subject status
    assert public_health.can_modify_subject_status?
    assert contact_tracer_user.can_modify_subject_status?
    assert public_health_enroller.can_modify_subject_status?
    assert super_user.can_modify_subject_status?
  end

  test 'can create subject history' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot create subject history
    assert_not admin.can_create_subject_history?
    assert_not analyst.can_create_subject_history?
    assert_not enroller.can_create_subject_history?

    # Can create subject history
    assert public_health.can_create_subject_history?
    assert contact_tracer_user.can_create_subject_history?
    assert public_health_enroller.can_create_subject_history?
    assert super_user.can_create_subject_history?
  end

  test 'can transfer patients' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot transfer patients
    assert_not admin.can_transfer_patients?
    assert_not analyst.can_transfer_patients?
    assert_not enroller.can_transfer_patients?
    assert_not contact_tracer_user.can_transfer_patients?

    # Can transfer patients
    assert public_health.can_transfer_patients?
    assert public_health_enroller.can_transfer_patients?
    assert super_user.can_transfer_patients?
  end

  test 'can see monitoring dashboards tab' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot see monitoring dashboards tab
    assert_not admin.can_see_monitoring_dashboards_tab?
    assert_not analyst.can_see_monitoring_dashboards_tab?
    assert_not enroller.can_see_monitoring_dashboards_tab?
    assert_not contact_tracer_user.can_see_monitoring_dashboards_tab?

    # Can see monitoring dashboards tab
    assert public_health.can_see_monitoring_dashboards_tab?
    assert public_health_enroller.can_see_monitoring_dashboards_tab?
    assert super_user.can_see_monitoring_dashboards_tab?
  end

  test 'can see enroller dashboard tab' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot see enroller dashboard tab
    assert_not admin.can_see_enroller_dashboard_tab?
    assert_not analyst.can_see_enroller_dashboard_tab?
    assert_not public_health.can_see_enroller_dashboard_tab?
    assert_not contact_tracer_user.can_see_enroller_dashboard_tab?
    assert_not public_health_enroller.can_see_enroller_dashboard_tab?
    assert_not super_user.can_see_enroller_dashboard_tab?

    # Can see enroller dashboard tab
    assert enroller.can_see_enroller_dashboard_tab?
  end

  test 'can see admin panel tab' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot see admin panel tab
    assert_not admin.can_see_admin_panel_tab?
    assert_not analyst.can_see_admin_panel_tab?
    assert_not public_health.can_see_admin_panel_tab?
    assert_not enroller.can_see_admin_panel_tab?
    assert_not contact_tracer_user.can_see_admin_panel_tab?
    assert_not public_health_enroller.can_see_admin_panel_tab?

    # Can see admin panel tab
    assert super_user.can_see_admin_panel_tab?
  end

  test 'can see analytics tab' do
    admin = create(:admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    super_user = create(:super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot see analytics tab
    assert_not admin.can_see_analytics_tab?
    assert_not analyst.can_see_analytics_tab?
    assert_not contact_tracer_user.can_see_analytics_tab?

    # Can see analytics tab
    assert enroller.can_see_analytics_tab?
    assert public_health.can_see_analytics_tab?
    assert public_health_enroller.can_see_analytics_tab?
    assert super_user.can_see_analytics_tab?
  end

  test 'can send admin emails' do
    usa_admin = create(:usa_admin_user)
    non_usa_admin = create(:non_usa_admin_user)
    enroller = create(:enroller_user)
    public_health_enroller = create(:public_health_enroller_user)
    public_health = create(:public_health_user)
    analyst = create(:analyst_user)
    usa_super_user = create(:usa_super_user)
    non_usa_super_usa = create(:non_usa_super_user)
    contact_tracer_user = create(:contact_tracer_user)

    # Cannot send admin emails
    assert_not non_usa_admin.can_send_admin_emails?
    assert_not public_health.can_send_admin_emails?
    assert_not enroller.can_send_admin_emails?
    assert_not public_health_enroller.can_send_admin_emails?
    assert_not analyst.can_send_admin_emails?
    assert_not non_usa_super_usa.can_send_admin_emails?
    assert_not contact_tracer_user.can_send_admin_emails?

    # Can send admin emails
    assert usa_admin.can_send_admin_emails?
    assert usa_super_user.can_send_admin_emails?
  end
end
