module Oare
end

if defined?(Rails) && Rails::VERSION::MAJOR == 3
  require 'active_resource'
  require 'active_resource/base'
  require 'active_resource/validations'

  require File.expand_path('active_resource_override/connection', File.dirname(__FILE__))
  require File.expand_path('active_resource_override/errors'    , File.dirname(__FILE__))
  require File.expand_path('active_resource_override/base'      , File.dirname(__FILE__))
  require File.expand_path('extensions/gateway'                 , File.dirname(__FILE__))
end
