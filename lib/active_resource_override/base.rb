module Oare::Resource
  def self.included(base)
    base.instance_eval <<-RUBY

      alias_method :original_save, :save
      undef_method :save
      define_method :save do |options = {}, query_options = nil|
        begin
          perform_validation = case options
            when Hash
              options.delete(:validate) != false
            when NilClass
              true
            else
              options
            end

          # clear the remote validations so they don't interfere with the local
          # ones. Otherwise we get an endless loop and can never change the
          # fields so as to make the resource valid
          @remote_errors = nil
          if perform_validation && valid? || !perform_validation
            save_without_validation(options, query_options)
            true
          else
            false
          end
        rescue ActiveResource::ResourceInvalid => error
          # cache the remote errors because every call to <tt>valid?</tt> clears
          # all errors. We must keep a copy to add these back after local
          # validations
          @remote_errors = error
          load_remote_errors(@remote_errors, true)
          false
        end
      end

      alias_method :original_save_without_validation, :save_without_validation
      undef_method :save_without_validation
      define_method :save_without_validation do |path_options = {}, query_options = nil|
        new? ? create(path_options, query_options) : update(path_options, query_options)
      end

      alias_method :original_create, :create
      undef_method :create
      define_method :create do |path_options = {}, query_options = nil|
        connection.post(create_path(path_options, query_options), encode, self.class.headers).tap do |response|
          self.id = id_from_response(response)
          load_attributes_from_response(response)
        end
      end

      alias_method :original_update, :update
      undef_method :update
      define_method :update do |path_options = {}, query_options = nil|
        connection.put(update_path(path_options, query_options), encode, self.class.headers).tap do |response|
          load_attributes_from_response(response)
        end
      end

    RUBY

    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.set_default_values
  end

  module InstanceMethods
    attr_accessor :nested_attributes_values

    def initialize(attributes = {})
      @nested_attributes_values ||= {}
      self.class.instance_variable_get(:@nested_attributes).each do |key, value|
        @nested_attributes_values[key] = collection = attributes.delete(key)
        next unless collection

        collection.each do |index, associate_attributes|
          nested_model = value.to_s
          collection   = []
          collection[index.to_i] = nested_model.singularize.camelize.constantize.new(associate_attributes)
          instance_variable_set("@#{nested_model}", collection)
        end
      end
      super
    end

    def create_path(options = {}, query_options = {})
      self.class.create_path(prefix_options.merge(options), query_options)
    end

    def update_path(options = {}, query_options = {})
      self.class.update_path(to_param, prefix_options.merge(options), query_options)
    end

    def encode(options={})
      if new?
        keys = nested_attributes_values.keys
        super(options.merge(:methods => keys))
      else
        super
      end
    end

    def errors
      @errors ||= Oare::Errors.new(self)
    end
  end # Instance Methods

  module ClassMethods
    attr_accessor :access_token
    attr_accessor :associations
    attr_accessor :nested_attributes

    def set_default_values
      self.nested_attributes ||= {}
      self.associations      ||= []
    end

    def has_many(association_id, options = {})
      class_name = options[:class_name] || association_id.to_s.singularize.camelize
      associations << class_name.constantize

      define_method(association_id) do |*args|
        current_value = instance_variable_get("@#{association_id}".to_sym)
        return current_value if current_value

        resource = find_or_create_resource_for_collection(class_name)
        value = if self.new_record? then [resource.new]
          else
          # TODO:
          # Request for users of account
          # Use an instance variable version of the access token
          #
          end
        instance_variable_set(
          "@#{association_id}".to_sym, value)
      end
    end

    def accepts_nested_attributes_for(association_id, options = {})
      nested_attributes["#{association_id}_attributes"] = association_id
      define_method("#{association_id}_attributes=") do |*args|
        # TODO
      end

      define_method("#{association_id}_attributes") do
        nested_attributes_values["#{association_id}_attributes"]
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

    def create_path(path_options = {}, query_options = nil)
      path = path_options.delete(:path)
      prefix_options = path_options
      return collection_path(prefix_options, query_options) unless path
      "/#{path}.#{format.extension}#{query_string(query_options)}"
    end

    def update_path(id, path_options = {}, query_options = nil)
      path = path_options.delete(:path)
      prefix_options = path_options
      return collection_path(id, prefix_options, query_options) unless path
      "/#{path}/#{URI.escape id.to_s}.#{format.extension}#{query_string(query_options)}"
    end

  end # Class Methods
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

