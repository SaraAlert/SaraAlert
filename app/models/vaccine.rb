# frozen_string_literal: true

# Vaccine represents a vaccine record for a patient

class Vaccine < ApplicationRecord
    belongs_to :patient

end