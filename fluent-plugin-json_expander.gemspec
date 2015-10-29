# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-json_expander"
  spec.version       = "0.0.1"
  spec.authors       = ["Uchio KONDO"]
  spec.email         = ["udzura@udzura.jp"]

  spec.summary       = %q{Run the sub-matcher created from accepted json data}
  spec.description   = %q{Run the sub-matcher created from accepted json data}
  spec.homepage      = "https://github.com/udzura/fluent-plugin-json_expander"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_development_dependency "test-unit", ">= 3"
  spec.add_development_dependency "test-unit-rr"
  spec.add_development_dependency "power_assert"
  spec.add_development_dependency "pry"
end
