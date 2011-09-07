require 'rake'
require 'rake/clean'

require 'rubygems'
require 'rubygems/package_task'

gem 'rdoc'
require 'rdoc/task'

desc 'Generate documentation for the ore plugin.'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'OAuth Active Resource Extension'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.load(Dir['*.gemspec'].first)
package = Gem::PackageTask.new(spec)
package.define
