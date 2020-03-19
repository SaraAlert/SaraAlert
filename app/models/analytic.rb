# frozen_string_literal: true

# Analytic
class Analytic < ApplicationRecord
  has_many :monitoree_counts
  has_many :monitoree_snapshots
end
