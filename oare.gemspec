# encouding: utf -8
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  ## Basic Information
  #
  s.name     = 'oare'
  s.version  = '0.1.13'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version     = '~> 1.9'
  s.required_rubygems_version = '>= 1.3.6'
  s.authors  = ['Nelvin Driz', 'Marjun Pagalan']
  s.email    = ['ndriz@exist.com', 'mpagalan@exist.com']
  s.licenses = ['MIT']
  s.summary  = 'Oauth Active Resource Extension'
  s.description = %q{
    Allows Oauth usage in Active Resource
    }

  ## Rdoc Settings
  #
  s.has_rdoc = true
  s.extra_rdoc_files = 'README.rdoc'
  s.rdoc_options = %w{--main README.rdoc}

  ## External Name in RubyForge
  #
  s.rubyforge_project = 'oare'

  ## Gem Files
  #
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

  ## Dependency
  #
  s.add_dependency 'activeresource', '~> 3.1'
  s.add_development_dependency 'rdoc'
end
