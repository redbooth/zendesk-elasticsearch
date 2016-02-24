# Make a site name available throught the application
SITE_NAME = Rails.application.config.site_name

# Zendesk configuration
ZENDESK_ADMIN_USER  = Rails.application.secrets.zendesk_admin_user
ZENDESK_ADMIN_TOKEN = Rails.application.secrets.zendesk_admin_token
ZENDESK_HOST_NAME   = Rails.application.config.zendesk_host_name
ZENDESK_HOST_PORT   = Rails.application.config.zendesk_host_port

# Elasticsearch configuration
ES_HOST_NAME = Rails.application.config.es_host_name
ES_HOST_PORT = Rails.application.config.es_host_port

# ES Connection
ES_HTTP_CONNECTION = ConnectionBuilder.new(host: ES_HOST_NAME,
                                           port: ES_HOST_PORT).build
# ES Request Builder
ES_REQUEST_BUILDER = RequestBuilder.new

# Zendesk Connection
ZENDESK_HTTP_CONNECTION = ConnectionBuilder.new(host: ZENDESK_HOST_NAME,
                                                port: ZENDESK_HOST_PORT,
                                                use_ssl: true).build
# Zendesk Request Builder
ZENDESK_REQUEST_BUILDER = RequestBuilder.new(user: [ZENDESK_ADMIN_USER,
                                                    '/token'].join(''),
                                             token: ZENDESK_ADMIN_TOKEN)

# Zendesk Information Stores
ZENDESK_USER_STORE = ZDStore.new('/api/v2/users/show_many.json',
                                 ZDUser,
                                 'users')
ZENDESK_ORG_STORE  = ZDStore.new('/api/v2/organizations/show_many.json',
                                 ZDOrganization,
                                 'organizations')

# Zendesk ticket start date: How old will you go
ZENDESK_TICKET_START_DATE = Rails.application.config.zendesk_ticket_start_date

# Search definition file
SEARCH_DEFINITION = File.read(Rails.application.config.es_search_query_file)
