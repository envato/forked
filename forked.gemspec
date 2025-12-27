# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "forked/version"

Gem::Specification.new do |spec|
  spec.name          = "forked"
  spec.version       = Forked::VERSION
  spec.authors       = ["Steve Hodgkiss"]
  spec.email         = ["steve@hodgkiss.me"]
  spec.license       = "MIT"

  spec.summary       = "Manage long running forked processes"
  spec.description   = ""
  spec.homepage      = "https://github.com/envato/forked"

  spec.metadata      = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri"   => "#{spec.homepage}/issues",
    "changelog_uri"     => "#{spec.homepage}/releases",
    "documentation_uri" => "https://www.rubydoc.info/gems/forked/#{spec.version}",
    "source_code_uri"   => spec.homepage,
  }

  spec.required_ruby_version = ">= 2.5.0"

  spec.files = Dir["lib/**/*.rb"] + Dir["*.txt"] + Dir["*.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "logger", "~> 1"

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
end
