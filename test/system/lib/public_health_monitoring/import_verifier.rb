# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
    
  def verify_epi_x_selection(jurisdiction_id, workflow, file_name, rejects)
  end

  def verify_sara_alert_format_selection(jurisdiction_id, workflow, file_name, rejects)
  end

  def verify_epi_x_import(jurisdiction_id, workflow, file_name, rejects)
  end

  def verify_sara_alert_format_import(jurisdiction_id, workflow, file_name, rejects)
  end
end
