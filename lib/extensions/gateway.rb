module Oare
  module Gateway
    def method_missing(method, *args, &block)
      collection = ::ActiveResource::Base.oauth_enabled_classes
      if collection.keys.include? method
        constant = collection[method].join('::').constantize
        constant.access_token = self.access_token
        #Rails.logger.info  constant.access_token.inspect
        #Rails.logger.info  ::ActiveResource::Base.access_token.inspect
        #sleep 20
        constant
      else
        super(method, *args, &block)
      end
    end

    def access_token
      ## This method assumes that the Gateway Model has the fields/methods for:
      #  oauth_token        : string,
      #  oauth_token_secret : string,
      #  consumer           : consumer token
      #

      OAuth::AccessToken.new(consumer, oauth_token, oauth_token_secret)
    end
  end
end
