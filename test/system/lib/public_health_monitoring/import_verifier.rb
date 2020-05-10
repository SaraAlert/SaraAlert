# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
    
  def verify_import_epi_x(jurisdiction_id, workflow, file_name, rejects)
    sleep(inspection_time=1)
  end

  def verify_import_sara_alert_format(jurisdiction_id, workflow, file_name, rejects)
    sleep(inspection_time=1)
  end
end
