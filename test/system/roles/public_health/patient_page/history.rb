# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'history_verifier'

class PublicHealthPatientPageHistory < ApplicationSystemTestCase
  @@public_health_patient_page_history_verifier = PublicHealthPatientPageHistoryVerifier.new(nil)

  def add_comment(user_label, comment)
    fill_in 'comment', with: comment
    click_on 'Add Comment'
    @@public_health_patient_page_history_verifier.verify_comment(user_label, comment)
  end
end
