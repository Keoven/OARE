module Oare
  module Resource

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
      base.set_default_values
    end

    module InstanceMethods
      def initialize(attributes = {})
        self.class.instance_variable_get(:@nested_attributes).each do |key, value|
          collection = attributes.delete(key)
          next unless collection
          attributes[value] = collection.map {|i, a| a}
        end
        super
      end
    end

    module ClassMethods
      attr_accessor :access_token
      attr_accessor :associations
      attr_accessor :nested_attributes

      def set_default_values
        self.nested_attributes ||= {}
        self.associations ||= []
      end

      def has_many(association_id, options = {})
        class_name = options[:class_name] || association_id.to_s.singularize.camelize
        associations << class_name.constantize

        define_method(association_id) do |*args|
          resource = find_or_create_resource_for_collection(class_name)
          if self.new_record? then [resource.new]
          else
            # TODO:
            # Request for users of account
            # Use an instance variable version of the access token
            #
          end
        end
      end

      def accepts_nested_attributes_for(association_id, options = {})
        nested_attributes["#{association_id}_attributes"] = association_id
        define_method("#{association_id}_attributes=") do |*args|
          # TODO
        end
      end

      def access_token=(token)
        @access_token = token
        self.site     = token.consumer.site
      end

      def connection(refresh = true)
        self.access_token ? self.oauth_connection : super
      end

      def oauth_connection(refresh = true)
        associations.each do |model_constant|
          model_constant.access_token = self.access_token
        end if associations

        @connection = Oare::Connection.new(self.access_token) if @connection.nil? || refresh
        @connection.timeout = timeout if timeout
        @connection
      end
    end
  end # Oare Resource

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
    def requires_oauth
      # Extend ActiveResource with this Module
      #
      include Oare::Resource
      self.oauth_enabled_classes ||= {}
      class_name = self.to_s.split('::')
      key        = class_name[-1].underscore.to_sym
      unless self.oauth_enabled_classes.keys.include? key
        self.oauth_enabled_classes.merge!(key => class_name)
      end
    end
  end
end

