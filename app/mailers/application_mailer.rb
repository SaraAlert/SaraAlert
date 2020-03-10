# frozen_string_literal: true

# ApplicationMailer: base mailer
class ApplicationMailer < ActionMailer::Base
  default from: 'notifications@SaraAlert.mitre.org'
  layout 'mailer'
end
