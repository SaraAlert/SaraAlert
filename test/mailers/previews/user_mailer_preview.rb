class UserMailerPreview < ActionMailer::Preview
    def purge_notification
        UserMailer.with(user: User.first).purge_notification
    end
end