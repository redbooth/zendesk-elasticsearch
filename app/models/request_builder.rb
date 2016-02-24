# RequestBuilder objects are used to construct Net:HTTP requests
# throughout the application
class RequestBuilder
  def initialize(user: nil, token: nil)
    @user       = user
    @token      = token
  end

  def build(request_type:, route:, payload: nil, param_hash: nil)
    # Add paramaters from a hash
    unless param_hash.nil?
      route = [route, URI.encode_www_form(param_hash)].join('?')
    end

    # Create the request object
    begin
      request = get_request_of_type(request_type, route)
    rescue ArgumentError => e
      raise ArgumentError, e.message, caller
    end

    # Give it a body
    request.body = payload unless payload.nil?

    # Support basic authorization with a user and password
    request.basic_auth @user, @token unless @user.nil? || @token.nil?
    request
  end

  private

  def get_request_of_type(request_type, url)
    case request_type
    when 'GET'
      request = Net::HTTP::Get.new(url)
    when 'PUT'
      request = Net::HTTP::Put.new(url)
    when 'DELETE'
      request = Net::HTTP::Delete.new(url)
    when 'POST'
      request = Net::HTTP::Post.new(url)
    else
      error_msg = "Unimplemented HTTP method: #{request_type}"
      fail ArgumentError, error_msg, caller
    end
    request
  end
end
