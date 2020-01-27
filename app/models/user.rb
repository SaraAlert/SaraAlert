class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :created_patients, class_name: 'Patient', foreign_key: 'creator_id'

  # Can this user create a new Patient?
  def can_create_patient?
      has_role?(:enroller) || has_role?(:admin)
  end

  # Can this user view a Patient?
  def can_view_patient?
    has_role?(:enroller) || has_role?(:monitor) || has_role?(:admin)
  end
end
