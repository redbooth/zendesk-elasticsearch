# class methods for testing the connectivity with the
# Elasticsearch cluster and Zendesk API
class ConnectionTester
  # tests if the elasticsearch cluster responds to a basic GET request
  def self.test_es_connection
    request = ES_REQUEST_BUILDER.build(request_type: 'GET',
                                       route: '/')
    !ES_HTTP_CONNECTION.quick_request(request).nil?
  end

  # tests if the Zendesk services respond to a basic GET request
  def self.test_zendesk_connection
    request = ZENDESK_REQUEST_BUILDER.build(request_type: 'GET',
                                            route: '/')
    !ZENDESK_HTTP_CONNECTION.quick_request(request).nil?
  end
end
