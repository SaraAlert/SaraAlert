# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    UserMailer.welcome_email(User.first, '123456ab!')
  end

  def purge_notification
    UserMailer.with(user: User.first).purge_notification
  end
end
