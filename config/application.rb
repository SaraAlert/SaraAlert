require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SARAAlert
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    # Load environment variables from config/local_env.yml
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end
    # Setup which 3rd party queing system to use
    config.active_job.queue_adapter = :sidekiq
    config.exceptions_app = self.routes

    # Set default mailer queue
    config.action_mailer.deliver_later_queue_name = :mailers
  end
end
