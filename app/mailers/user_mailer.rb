# frozen_string_literal: true

# UserMailer: mailers for users
class UserMailer < ApplicationMailer
  default from: 'notifications@SaraAlert.mitre.org'

  def welcome_email(user, password)
    @user = user
    @password = password
    mail(to: user.email, subject: 'Welcome to the Sara Alert system')
  end
end
