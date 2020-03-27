# frozen_string_literal: true

# MonitoreeCount: a specific count of monitorees under certain conditions used for analytics
class MonitoreeCount < ApplicationRecord
  belongs_to :analytic
end
