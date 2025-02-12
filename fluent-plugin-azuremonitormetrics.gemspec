# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-azuremonitormetrics"
  gem.version       = "0.0.4"
  gem.authors       = ["Ilana Kantorov"]
  gem.email         = ["ilanak@microsoft.com"]
  gem.description   = %q{Input plugin for Azure Monitor Metrics.}
  gem.homepage      = "https://github.com/Azure/fluent-plugin-azuremonitormetrics"
  gem.summary       = gem.description
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "fluentd", "~> 1.7.4"
  gem.add_dependency "azure_mgmt_monitor", "~> 0.17.5"
  gem.add_development_dependency "rake", "~> 13.0.1"
  gem.add_development_dependency "test-unit", "~> 3.3.4"
  gem.license = 'MIT'
end
