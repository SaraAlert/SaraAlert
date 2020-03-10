# frozen_string_literal: true

# ApplicationRecord: base model
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
