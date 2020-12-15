# frozen_string_literal: true

# Helper method that will invalidate the hash of all jurisdictions and ids
module JurisdictionIdsAndPathsCacheInvalidator
  def self.invalidate
    # While this looks similar to a Regular Expression, it is actually
    # Redis KEYS syntax.
    Rails.cache.delete_matched('*jurisdiction_ids_and_paths*')
  end
end
