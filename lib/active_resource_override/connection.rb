class NilAccessToken < Exception; end

class Ore::Connection < ActiveResource::Connection
  attr_reader   :access_token

  def initialize(token, format = ActiveResource::Formats::XmlFormat)
    @access_token = token
    @user = @password = nil
    @uri_parser = URI.const_defined?(:Parser) ? URI::Parser.new : URI
    self.site = access_token.consumer.site
    self.format = format
  end

  def get_without_decoding(path, headers = {})
    request(:get, path, build_request_headers(headers, :get))
  end

  def handle_response(response)
    return super(response)
  rescue ActiveResource::ClientError => exc
    begin
      error_message = "#{format.decode response.body}"
      if not error_message.nil? or error_message == ""
        exc.response.instance_eval do ||
          @message = error_message
        end
      end
    ensure
      raise exc
    end
  end

private
  def request(method, path, *arguments)
    raise NilAccessToken if access_token.nil?
    response = access_token.request(method, path, *arguments)
    handle_response(response)
  rescue Timeout::Error => e
    raise TimeoutError.new(e.message)
  end

end
