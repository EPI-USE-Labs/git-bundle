# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_bundle/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-bundle'
  spec.version       = GitBundle::VERSION
  spec.authors       = ['Pierre Pretorius']
  spec.email         = ['pierre@labs.epiuse.com']

  spec.summary       = %q{Makes life easier when working with git and local overrides of bundled gems.}
  spec.description   = %q{Makes life easier when working with git and local overrides of bundled gems.}
  spec.homepage      = 'https://github.com/EPI-USE-Labs/git-bundle'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = 'gitb'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
end
