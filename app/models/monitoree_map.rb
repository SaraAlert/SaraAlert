# frozen_string_literal: true

# MonitoreeMap: a county of monitorees currently being monitored by workflow, state, and county used for analytics
class MonitoreeMap < ApplicationRecord
  belongs_to :analytic
end
