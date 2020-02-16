class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :validatable, :lockable

  # Validate password complexity
  validate :password_complexity
  def password_complexity
    if password.present?
      # Passwords must have characters from at least two groups, identified by these regexes (last one is punctuation)
      matches = [/[a-z]/, /[A-Z]/, /[0-9]/, /[^\w\s]/].select { |rx| rx.match(password) }.size
      unless matches >= 2
        errors.add :password, "must include characters from at least two groups (lower case, upper case, numbers, special characters)"
      end
    end
  end

  has_many :created_patients, class_name: 'Patient', foreign_key: 'creator_id'

  # TODO: Can one person have access to two jurisdictions that are not hierarchical? May want has_many through
  belongs_to :jurisdiction

  # Patients this user can view through their jurisdiction access
  def viewable_patients
    jurisdiction.all_patients
  end

  # Patients this user has enrolled
  def enrolled_patients
    created_patients
  end

  # Get a patient (that this user is allowed to get)
  def get_patient(id)
    if has_role?(:enroller)
      created_patients.find_by_id(id)
    elsif has_role?(:monitor)
      viewable_patients.find_by_id(id)
    elsif has_role?(:admin)
      Patient.find_by_id(id)
    end
  end

  # Can this user create a new Patient?
  def can_create_patient?
      has_role?(:enroller) || has_role?(:admin)
  end

  # Can this user view a Patient?
  def can_view_patient?
    has_role?(:enroller) || has_role?(:monitor) || has_role?(:admin)
  end

  # Can this user edit a Patient?
  def can_edit_patient?
    has_role?(:enroller) || has_role?(:monitor) || has_role?(:admin)
  end

  # Can this user view Patient assessments?
  def can_view_patient_assessments?
    has_role?(:monitor) || has_role?(:admin)
  end

  # Can this user view the monitor dashboard?
  def can_view_monitor_dashboard?
    has_role?(:monitor) || has_role?(:admin)
  end

  # Allow information on the user's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  def as_json(options = {})
    super((options || {}).merge(methods: :jurisdiction_path))
  end

end
