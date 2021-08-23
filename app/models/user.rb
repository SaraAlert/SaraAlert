# frozen_string_literal: true

# User: user model
class User < ApplicationRecord
  audited only: %i[locked_at jurisdiction_id created_at api_enabled role email authy_enabled
                   force_password_change last_sign_in_with_authy notes], max_audits: 1000

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :authy_authenticatable, :database_authenticatable, :registerable, :validatable, :lockable, :password_expirable, :password_archivable, :trackable

  validates :role, inclusion: { in: Roles.all_role_values }
  validates :notes, length: { maximum: 5000 }

  # Validate password complexity
  validate :password_complexity
  def password_complexity
    return if password.blank?

    # Passwords must have characters from at least two groups, identified by these regexes (last one is punctuation)
    matches = [/[a-z]/, /[A-Z]/, /[0-9]/, /[^\w\s]/].count { |rx| rx.match?(password) }
    errors.add :password, 'must include characters from at least three groups (lower case, upper case, numbers, special characters)' unless matches >= 3
  end

  has_many :created_patients, class_name: 'Patient', foreign_key: 'creator_id', dependent: nil, inverse_of: 'creator'

  has_many :downloads, dependent: :destroy
  has_many :export_receipts, dependent: :destroy
  has_many :user_filters, dependent: :destroy
  has_many :user_export_presets, dependent: :destroy
  has_many :contact_attempts, dependent: nil

  belongs_to :jurisdiction

  # Random password for temp password changes
  def self.rand_gen
    SecureRandom.base58(10) +
      (33 + SecureRandom.random_number(14)).chr(Encoding::ASCII) +
      (97 + SecureRandom.random_number(26)).chr(Encoding::ASCII) +
      (65 + SecureRandom.random_number(26)).chr(Encoding::ASCII)
  end

  # Patients this user can view through their jurisdiction access
  def viewable_patients
    jurisdiction.all_patients_excluding_purged
  end

  # Patients this user has enrolled
  def enrolled_patients
    created_patients.where(purged: false)
  end

  def patients
    return viewable_patients if role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER) || role?(Roles::CONTACT_TRACER)

    return enrolled_patients if role?(Roles::ENROLLER)

    nil
  end

  # Get a patient (that this user is allowed to get)
  def get_patient(id)
    if role?(Roles::ENROLLER)
      enrolled_patients.find_by(id: id)
    elsif role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER) || role?(Roles::CONTACT_TRACER)
      viewable_patients.find_by(id: id)
    elsif role?(Roles::ADMIN)
      nil
    end
  end

  # Get multiple patients (that this user is allowed to get)
  def get_patients(ids)
    if role?(Roles::ENROLLER)
      enrolled_patients.find(ids)
    elsif role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER) || role?(Roles::CONTACT_TRACER)
      viewable_patients.find(ids)
    elsif role?(Roles::ADMIN)
      nil
    end
  end

  # Get jurisdictions that the user can transfer patients into
  def jurisdictions_for_transfer
    if can_transfer_patients?
      # Allow all jurisdictions as valid transfer options.
      Jurisdiction.all.where.not(name: 'USA').pluck(:id, :path).to_h
    else
      # Otherwise, only show jurisdictions within hierarchy.
      jurisdiction.subtree.pluck(:id, :path).to_h
    end
  end

  # Allow information on the user's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Override as_json to include jurisdiction_path
  def as_json(options = {})
    super((options || {}).merge(methods: :jurisdiction_path))
  end

  #############################################################################
  # Access Restrictions for users
  #############################################################################

  # Can this user view User audits?
  def can_view_user_audits?
    role?(Roles::ADMIN) || role?(Roles::SUPER_USER)
  end

  # Can this user use the API?
  def can_use_api?
    api_enabled
  end

  # Can this user create a new Patient?
  def can_create_patient?
    role?(Roles::ENROLLER) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view a Patient?
  def can_view_patient?
    role?(Roles::ENROLLER) || role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user export?
  def can_export?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user import?
  def can_import?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user manage saved filters?
  def can_manage_saved_filters?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user manage saved export_presets?
  def can_manage_saved_export_presets?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit a Patient?
  def can_edit_patient?
    role?(Roles::ENROLLER) || role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit a Patient's monitoring information?
  def can_edit_patient_monitoring_info?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view Patient vaccines?
  def can_view_patient_vaccines?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit Patient vaccines?
  def can_edit_patient_vaccines?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create Patient vaccines?
  def can_create_patient_vaccines?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view Patient lab results?
  def can_view_patient_laboratories?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit Patient lab results?
  def can_edit_patient_laboratories?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create Patient lab results?
  def can_create_patient_laboratories?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view Patient close contacts?
  def can_view_patient_close_contacts?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit Patient close contacts?
  def can_edit_patient_close_contacts?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create Patient close contacts?
  def can_create_patient_close_contacts?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user enroll Patient close contacts?
  def can_enroll_patient_close_contacts?
    role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view Patient assessments?
  def can_view_patient_assessments?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user edit Patient assessments?
  def can_edit_patient_assessments?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create Patient assessments?
  def can_create_patient_assessments?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user download data for an specific record on the Monitoree page?
  def can_download_monitoree_data?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view the public health dashboard?
  def can_view_public_health_dashboard?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user view the enroller dashboard?
  def can_view_enroller_dashboard?
    role?(Roles::ENROLLER)
  end

  # Can view analytics
  def can_view_analytics?
    role?(Roles::ANALYST) || role?(Roles::ENROLLER) || role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can view the epi stats on the analytics page
  def can_view_epi_analytics?
    role?(Roles::ANALYST) || role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user modify subject status?
  def can_modify_subject_status?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create subject history?
  def can_create_subject_history?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user create contact attempt?
  def can_create_subject_contact_attempt?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::CONTACT_TRACER) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user transfer patients out of their jurisdiction hierarchy?
  def can_transfer_patients?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Does this user need to see the Monitoring Dashboards tab?
  # NOTE: Contact Tracers don't need to see this tab because it is their only option
  def can_see_monitoring_dashboards_tab?
    role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Does this user need to see the Enroller Dashboard tab?
  def can_see_enroller_dashboard_tab?
    role?(Roles::ENROLLER)
  end

  # Does this user need to see the Admin Panel tab?
  # NOTE: Admins don't need to see this tab because it is their only option
  def can_see_admin_panel_tab?
    role?(Roles::SUPER_USER)
  end

  # Does this user need to see the Analytics tab?
  # NOTE: Analysts don't need to see this tab because it is their only option
  def can_see_analytics_tab?
    role?(Roles::ENROLLER) || role?(Roles::PUBLIC_HEALTH) || role?(Roles::PUBLIC_HEALTH_ENROLLER) || role?(Roles::SUPER_USER)
  end

  # Can this user send system email messages?
  def can_send_admin_emails?
    (role?(Roles::ADMIN) || role?(Roles::SUPER_USER)) && jurisdiction&.name == 'USA' && jurisdiction&.is_root?
  end

  def can_access_admin_panel?
    role?(Roles::ADMIN) || role?(Roles::SUPER_USER)
  end

  def admin?
    role?(Roles::ADMIN)
  end

  def usa_admin?
    (role?(Roles::ADMIN) || role?(Roles::SUPER_USER)) && jurisdiction&.name == 'USA' && jurisdiction&.is_root?
  end

  def enroller?
    role?(Roles::ENROLLER)
  end

  def public_health?
    role?(Roles::PUBLIC_HEALTH)
  end

  def public_health_enroller?
    role?(Roles::PUBLIC_HEALTH_ENROLLER)
  end

  def analyst?
    role?(Roles::ANALYST)
  end

  def super_user?
    role?(Roles::SUPER_USER)
  end

  def contact_tracer?
    role?(Roles::CONTACT_TRACER)
  end

  def role?(role)
    self.role == role
  end
end
