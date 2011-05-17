module Oare
  module Resource
    def has_many(association_id, options = {})
      @associations ||= []
      class_name = options[:class_name] || association_id.to_s.singularize.camelize
      @associations << class_name.constantize
    end

    def connection(refresh = true)
      @associations.each do |model_constant|
        model_constant.access_token = self.access_token
      end if @associations

      @connection = Oare::Connection.new(self.access_token) if @connection.nil? || refresh
      @connection.timeout = timeout if timeout
      @connection
    end

  end

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

# Monkey Patch Active Resource and Action Controller
class ActiveResource::Base
  # --------------------------------------------------------------
  # Class Methods
  # --------------------------------------------------------------
  cattr_accessor :oauth_enabled_classes

  class << self
    attr_accessor :access_token

    def requires_oauth
      # Extend ActiveResource with this Module
      #
      extend Oare::Resource
      self.oauth_enabled_classes ||= {}
      class_name = self.to_s.split('::')
      key        = class_name[-1].underscore.to_sym
      unless self.oauth_enabled_classes.keys.include? key
        self.oauth_enabled_classes.merge!(key => class_name)
      end
    end

    def access_token=(token)
      @access_token = token
      self.site     = token.consumer.site
    end

  end
end

