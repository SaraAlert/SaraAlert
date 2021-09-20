# frozen_string_literal: true

# Analytic
class Analytic < ApplicationRecord
  has_many :monitoree_maps, dependent: nil
  has_many :monitoree_counts, dependent: nil
  has_many :monitoree_snapshots, dependent: nil
end
