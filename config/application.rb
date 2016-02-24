require File.expand_path('../boot', __FILE__)
require 'rails'
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Whatsup
  # Configuration for the Rails Application
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified
    # here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record
    # auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names.
    # Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from
    # config/locales/*.rb,yml
    # are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my',
    #                                              'locales',
    #                                              '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # grab all the library paths
    config.autoload_paths += %W(#{Rails.root}/lib)

    # TODO: - The following properties must be configured before you start the
    # web server

    # Choose a site name
    config.site_name            = ENV["SEARCH_SITE_NAME"].presence || 'Insert Your Site Name Here'

    # Define Token-based Zendesk logins
    config.zendesk_host_name    = ENV["ZENDESK_HOST_NAME"]
    config.zendesk_host_port    = ENV["ZENDESK_HOST_PORT"].presence || '443'

    # Identify the elasticsearch host
    config.es_host_name         = ENV["ES_HOST_NAME"].presence || 'localhost'
    config.es_host_port         = ENV["ES_HOST_PORT"].presence || '9200'

    # Specify YAML file with the ES search query
    config.es_search_query_file = "#{Rails.root}/config/search.yml.erb"

    # Set the UNIX timestamp of the first ticket you care about indexing
    config.zendesk_ticket_start_date = ENV["ZENDESK_START_DATE"].presence || 1_420_070_400
  end
end
