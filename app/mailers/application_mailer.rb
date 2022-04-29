# frozen_string_literal: true

# ApplicationMailer: base mailer
class ApplicationMailer < ActionMailer::Base
  default from: ADMIN_OPTIONS['default_mailer']
  layout 'mailer'
end
