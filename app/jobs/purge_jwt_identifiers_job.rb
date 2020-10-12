# frozen_string_literal: true

# PurgeJwtIdentifiersJob: Purges JWT Identifiers that belong to expired JWTs
class PurgeJwtIdentifiersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    total_before = JwtIdentifier.count
    eligible = JwtIdentifier.purge_eligible
    eligible_count = eligible.count

    # Purge all
    eligible.destroy_all

    # Get total after
    total_after = JwtIdentifier.count

    # Send results
    UserMailer.jwt_identifier_purge_job_email(total_before, eligible_count, total_after).deliver_now
  end
end
