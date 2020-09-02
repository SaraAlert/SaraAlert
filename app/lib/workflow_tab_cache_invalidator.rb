# frozen_string_literal: true

# Helper method that will invalidate the workflow tab counts
module WorkflowTabCacheInvalidator
  def self.invalidate_tab_counts_cache(jurisdiction_id)
    puts 'INVALIDATING CACHE'
    %w[exposure isolation].each do |workflow|
      %w[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out requiring_review reporting].each do |tab|
        Rails.cache.delete("#{jurisdiction_id}-#{workflow}-#{tab}")
      end
    end
  end
end
