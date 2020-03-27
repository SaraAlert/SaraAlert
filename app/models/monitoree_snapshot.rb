# frozen_string_literal: true

# MonitoreeSnapshot: a snapshot of monitoree activity at a given time frame used for analytics
class MonitoreeSnapshot < ApplicationRecord
  belongs_to :analytic
end
