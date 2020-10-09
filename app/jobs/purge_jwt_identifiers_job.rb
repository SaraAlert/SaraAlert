# frozen_string_literal: true

# PurgeJwtIdentifiersJob: Purges JWT Identifiers that belong to expired JWTs
class PurgeJwtIdentifiersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    eligible = JwtIdentifier.purge_eligible
    eligible_count = eligible.count

    # Purge all
    eligible.destroy_all

    # Send results
    UserMailer.jwt_identifier_purge_job_email(eligible_count, [], eligible_count).deliver_now
  end
end
