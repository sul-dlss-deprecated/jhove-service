# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = "jhove-service"
  s.version     = "1.1.4"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Richard Anderson","Peter Mangiafico"]
  s.email       = ["rnanders@stanford.edu","petucket@stanford.edu"]
  s.summary     = "Generates JHOVE output and/or technicalMetadata"
  s.description = "Generates JHOVE output and/or technicalMetadata"

  s.required_rubygems_version = ">= 1.3.6"

  # Runtime dependencies
  s.add_dependency "nokogiri", ">=1.4.3.1"

  # Bundler will install these gems too if you've checked out lyber-utils source from git and run 'bundle install'
  # It will not add these as dependencies if you require lyber-utils for other projects
  s.add_development_dependency "equivalent-xml", ">=0.2.2"
  s.add_development_dependency "rake", ">=0.8.7"
  s.add_development_dependency "rspec"
  s.add_development_dependency 'coveralls'

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.rdoc README.rdoc)
  s.require_path = 'lib'
end
