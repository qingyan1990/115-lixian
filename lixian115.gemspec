# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lixian115/version'

Gem::Specification.new do |spec|
  spec.name          = "lixian115"
  spec.version       = Lixian115::VERSION
  spec.authors       = ["aiyanxu"]
  spec.email         = ["liqingyan1990@gmail.com"]
  spec.summary       = %q{ a command tool for 115 wangpan lixian util }
  spec.description   = %q{ a command tool for 115 wangpan lixian util }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "thor", ">= 0.17.0"
  spec.add_dependency "rest-client", ">= 1.7.3"
end
