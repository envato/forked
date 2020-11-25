# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "forked/version"

Gem::Specification.new do |spec|
  spec.name          = "forked"
  spec.version       = Forked::VERSION
  spec.authors       = ["Steve Hodgkiss"]
  spec.email         = ["steve@hodgkiss.me"]

  spec.summary       = %q{Manage long running forked processes}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/envato/forked"

  spec.files = Dir["lib/**/*.rb"]
  spec.files += Dir['[A-Z]*']
  spec.require_paths = ['lib']

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
