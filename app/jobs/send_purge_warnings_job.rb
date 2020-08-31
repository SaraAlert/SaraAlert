# frozen_string_literal: true

# SendPurgeWarningsJob: sends purge warning reminder to admins
class SendPurgeWarningsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    UserMailer.purge_notification.deliver_later
  end
end
