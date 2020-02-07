namespace :user do

  # TODO: These are user management functions for testing until a web interface is developed
  
  desc "Add a user account"
  task add: :environment do
    roles = Role.pluck(:name)
    email = ENV["EMAIL"]
    raise "EMAIL must be provided" unless email
    password = ENV["PASSWORD"]
    raise "PASSWORD must be provided" unless password
    role = ENV["ROLE"]
    raise "ROLE must be provided and one of #{roles}" unless role && roles.include?(role)
    user = User.create!(email: email, password: password)
    user.add_role role
  end

  desc "Update a user's password"
  task update: :environment do
    roles = Role.pluck(:name)
    email = ENV["EMAIL"]
    raise "EMAIL must be provided" unless email
    user = User.find_by_email!(email)
    password = ENV["PASSWORD"]
    role = ENV["ROLE"]
    raise "PASSWORD or ROLE must be provided; ROLE must be one of one of #{roles}" unless password || (role && roles.include?(role))
    if password
      user.update_attributes!(password: password)
    end
    if role
      user.roles.each { |role| user.remove_role(role.name) }
      user.add_role role
    end
  end

  desc "Delete a user account"
  task delete: :environment do
    email = ENV["EMAIL"]
    raise "EMAIL must be provided" unless email
    User.where(email: email).delete_all
  end

end
