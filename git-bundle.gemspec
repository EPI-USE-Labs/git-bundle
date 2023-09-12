# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_bundle/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-bundle'
  spec.version       = GitBundle::VERSION
  spec.authors       = ['Pierre Pretorius', 'Divan Burger']
  spec.email         = ['pierre@labs.epiuse.com', 'divan@labs.epiuse.com']
  spec.summary       = %q{Simplifies working with gems from git repositories in combination with local overrides.}
  spec.description   = %q{Simplifies working with gems from git repositories in combination with local overrides.
                          See the github page for more detail.}
  spec.homepage      = 'https://github.com/EPI-USE-Labs/git-bundle'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = 'gitb'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.4.19'
end
