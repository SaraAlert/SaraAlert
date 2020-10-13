# frozen_string_literal: true

namespace :user do
  desc 'Add a user account'
  task add: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    roles = Roles.all_role_values
    jurisdictions = Jurisdiction.pluck(:name)
    email = ENV['EMAIL']
    raise 'EMAIL must be provided' unless email

    password = ENV['PASSWORD']
    unless password
      puts 'Generating random password'
      password = User.rand_gen
    end
    role = ENV['ROLE']
    raise "ROLE must be provided and one of #{roles}" unless role && roles.include?(role)

    jurisdiction = ENV['JURISDICTION']
    raise "JURISDICTION must be provided and one of #{jurisdictions}" unless jurisdiction&.include?(jurisdiction)

    user = User.create!(
      email: email,
      password: password,
      jurisdiction: Jurisdiction.find_by_name(jurisdiction),
      force_password_change: true, # Require user to change password on first login
      role: role
    )
    UserMailer.welcome_email(user, password).deliver_later
  end

  desc "Update a user's password and/or role and/or jurisdiction"
  task update: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    roles = Roles.all_role_values
    jurisdictions = Jurisdiction.pluck(:name)
    email = ENV['EMAIL']
    raise 'EMAIL must be provided' unless email

    user = User.find_by_email!(email)
    password = ENV['PASSWORD']
    role = ENV['ROLE']
    jurisdiction = ENV['JURISDICTION']
    unless password || (role && roles.include?(role)) || (jurisdiction && jurisdictions.include?(jurisdiction))
      raise "PASSWORD or ROLE or JURISDICTION must be provided; ROLE must be one of one of #{roles}; JURISDICTION must be one of #{jurisdictions}"
    end

    user.update_attributes!(password: password) if password
    user.update_attributes!(role: role) if role
    user.update_attributes!(jurisdiction: Jurisdiction.find_by_name(jurisdiction)) if jurisdiction
  end

  desc 'Delete a user account'
  task delete: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    email = ENV['EMAIL']
    raise 'EMAIL must be provided' unless email

    User.where(email: email).delete_all
  end

  desc 'List user accounts'
  task list: :environment do
    raise 'This task is only for use in a development environment' unless Rails.env == 'development'

    User.find_each do |user|
      puts "#{user.email.ljust(45, '.')} #{user.roles_name.join(' ')}"
    end
  end
end
