# Builds Net::HTTP objects used throughout the application. Only one
# builder is required for each host/port/use_ssl combination
class ConnectionBuilder
  def initialize(host:, port:, use_ssl: false)
    @host    = host
    @port    = port
    @use_ssl = use_ssl
  end

  def build
    http = Net::HTTP.new(@host, @port)
    http.use_ssl = @use_ssl
    http.extend(QuickRequest)
    http
  end
end

module QuickRequest

  # add a request method to include timeouts and the start block
  def quick_request(request)
    response = nil
    begin
      Timeout.timeout(10) do
        self.start do |http_connection|
          response = http_connection.request(request)
        end
      end
    rescue
      return nil
    end
    response
  end
end
