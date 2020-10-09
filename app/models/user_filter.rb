# frozen_string_literal: true

# UserFilter: a saved user filter
class UserFilter < ApplicationRecord
  belongs_to :user
end
