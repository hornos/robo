# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','robo','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'robo'
  s.version = Robo::VERSION
  s.author = 'Your Name Here'
  s.email = 'your@email.address.com'
  s.homepage = 'http://your.website.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
# Add your other files here if you make them
  s.files = %w(
bin/robo
lib/robo/version.rb
lib/robo/robo.rb
lib/robo.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','robo.rdoc']
  s.rdoc_options << '--title' << 'robo' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'robo'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('watir-webdriver')
  s.add_development_dependency('pry')
  s.add_runtime_dependency('gli','2.0.0')
end
