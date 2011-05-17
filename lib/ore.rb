module Ore
end

if defined?(Rails) && Rails::VERSION::MAJOR == 3
  require File.expand_path('active_resource_override/connection', File.dirname(__FILE__))
  require File.expand_path('active_resource_override/base'      , File.dirname(__FILE__))
end
