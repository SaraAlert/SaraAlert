# frozen_string_literal: true

# Helper method that will invalidate the hash of all jurisdictions and ids
module JurisdictionIdsAndPathsCacheInvalidator
  def self.invalidate
    Rails.cache.delete('all_jurisdiction_ids_and_paths')
  end
end
