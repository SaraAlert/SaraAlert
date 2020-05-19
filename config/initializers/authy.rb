Authy.api_key = ENV["AUTHY_API_KEY"]
Authy.api_uri = "https://api.authy.com/"

Devise::Models::AuthyAuthenticatable.module_eval do
    def with_authy_authentication?(request)
        if self.authy_id.present? && self.authy_enabled && self.authy_enforced
            return true
        end

        return false
    end
end