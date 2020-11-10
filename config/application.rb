require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Asselina
  class Application < Rails::Application

    Capybara.current_driver = :selenium_chrome
    # Capybara.current_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 10

    # config.eager_load = true
    config.autoload_paths += %W(#{config.root}/app)
    config.autoload_paths += %W(#{config.root}/lib)

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
