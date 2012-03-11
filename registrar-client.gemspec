Gem::Specification.new do |s|
  s.name        = "registrar-client"
  s.version     = "0.0.6"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Anthony Eden", "Enrique Comba", "Javier Acero"]
  s.email       = ["anthony.eden@dnsimple.com"]
  s.homepage    = "http://github.com/aeden/registrar-client"
  s.summary     = "Abstract interface and implementations for working with various domain registrars"
  s.description = "Abstract interface and implementations for working with various domain registrars."
 
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "httparty"
  s.add_dependency "tzinfo"
  s.add_dependency "nokogiri"
  s.add_dependency "builder"
 
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
 
  s.files        = Dir.glob("{examples,lib}/**/*") + %w(LICENSE Readme.md Spec.md)
  s.require_path = 'lib'
end
