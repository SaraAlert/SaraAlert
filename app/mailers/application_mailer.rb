# frozen_string_literal: true

# ApplicationMailer: base mailer
class ApplicationMailer < ActionMailer::Base
  default from: 'notifications@saraalert.org'
  layout 'mailer'
end
