# frozen_string_literal: true

# User: user model
class User < ApplicationRecord
  rolify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :authy_authenticatable, :database_authenticatable, :registerable, :validatable, :lockable, :password_expirable, :password_archivable

  # Validate password complexity
  validate :password_complexity
  def password_complexity
    return unless password.present?

    # Passwords must have characters from at least two groups, identified by these regexes (last one is punctuation)
    matches = [/[a-z]/, /[A-Z]/, /[0-9]/, /[^\w\s]/].select { |rx| rx.match(password) }.size
    errors.add :password, 'must include characters from at least three groups (lower case, upper case, numbers, special characters)' unless matches >= 3
  end

  has_many :created_patients, class_name: 'Patient', foreign_key: 'creator_id'

  has_many :downloads
  has_many :export_receipts

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
    jurisdiction.all_patients
  end

  # Patients this user has enrolled
  def enrolled_patients
    created_patients
  end

  def patients
    return viewable_patients if has_role?(:public_health) || has_role?(:public_health_enroller)

    return enrolled_patients if has_role?(:enroller)

    nil
  end

  # Get a patient (that this user is allowed to get)
  def get_patient(id)
    if has_role?(:enroller)
      enrolled_patients.find_by_id(id)
    elsif has_role?(:public_health)
      viewable_patients.find_by_id(id)
    elsif has_role?(:public_health_enroller)
      viewable_patients.find_by_id(id)
    elsif has_role?(:admin)
      nil
    end
  end

  # Get multiple patients (that this user is allowed to get)
  def get_patients(ids)
    if has_role?(:enroller)
      enrolled_patients.find(ids)
    elsif has_role?(:public_health)
      viewable_patients.find(ids)
    elsif has_role?(:public_health_enroller)
      viewable_patients.find(ids)
    elsif has_role?(:admin)
      nil
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

  # Can this user use the API?
  def can_use_api?
    api_enabled
  end

  # Can this user create a new Patient?
  def can_create_patient?
    has_role?(:enroller) || has_role?(:public_health_enroller)
  end

  # Can this user view a Patient?
  def can_view_patient?
    has_role?(:enroller) || has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user export?
  def can_export?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user import?
  def can_import?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user edit a Patient?
  def can_edit_patient?
    has_role?(:enroller) || has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user view Patient lab results?
  def can_view_patient_laboratories?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user edit Patient lab results?
  def can_edit_patient_laboratories?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user create Patient lab results?
  def can_create_patient_laboratories?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user view Patient close contacts?
  def can_view_patient_close_contacts?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user edit Patient close contacts?
  def can_edit_patient_close_contacts?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user create Patient close contacts?
  def can_create_patient_close_contacts?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user view Patient assessments?
  def can_view_patient_assessments?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user edit Patient assessments?
  def can_edit_patient_assessments?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user create Patient assessments?
  def can_create_patient_assessments?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user send a reminder email?
  def can_remind_patient?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user view the public health dashboard?
  def can_view_public_health_dashboard?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user view the enroller dashboard?
  def can_view_enroller_dashboard?
    has_role?(:enroller)
  end

  # Can view analytics
  def can_view_analytics?
    has_role?(:enroller) || has_role?(:public_health) || has_role?(:public_health_enroller) || has_role?(:analyst)
  end

  # Can this user modify subject status?
  def can_modify_subject_status?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user create subject history?
  def can_create_subject_history?
    has_role?(:public_health) || has_role?(:public_health_enroller)
  end

  # Can this user send system email messages?
  def can_send_admin_emails?
    has_role?(:admin) && jurisdiction&.name == 'USA'
  end

  # Can this user send system email messages?
  def admin?
    has_role?(:admin)
  end

  # Can this user send system email messages?
  def usa_admin?
    has_role?(:admin) && jurisdiction&.name == 'USA'
  end

  # Can this user send system email messages?
  def enroller?
    has_role?(:enroller)
  end

  # Can this user send system email messages?
  def public_health?
    has_role?(:public_health)
  end

  # Can this user send system email messages?
  def public_health_enroller?
    has_role?(:public_health_enroller)
  end

  # Can this user send system email messages?
  def analyst?
    has_role?(:analyst)
  end
end
