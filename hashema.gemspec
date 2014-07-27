$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "hashema/version"

Gem::Specification.new do |s|
  s.name        = "hashema"
  s.version     = Hashema::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Ben Christel"]
  s.homepage    = "http://github.com/benchristel/hashema"
  s.summary     = "hashema-#{Hashema::Version::STRING}"
  s.description = "Assert that JSONable objects conform to a schema"
  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += ["License.txt"]
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = [ "README.md" ]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_development_dependency "rspec", ">= 3.0.0"
end
