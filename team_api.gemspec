# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'team_api/version'

Gem::Specification.new do |s|
  s.name          = 'team_api'
  s.version       = TeamApi::VERSION
  s.authors       = ['Mike Bland', 'Amanda Robinson', 'Carlo Costino']
  s.email         = ['michael.bland@gsa.gov', 'amanda.robinson@gsa.gov', 'carlo.costino@gsa.gov']
  s.summary       = 'Compiles team information and publishes it as a JSON API'
  s.description   = (
    'Compiles information about team members, projects, etc. and exposes it ' \
    'via a JSON API.'
  )
  s.homepage      = 'https://github.com/18F/team_api'
  s.license       = 'CC0'

  s.files         = `git ls-files -z *.md bin lib`.split("\x0") + [
  ]
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_runtime_dependency 'bundler', '~> 1.10'
  s.add_runtime_dependency 'safe_yaml', '~> 1.0'
  s.add_runtime_dependency 'jekyll'
  s.add_runtime_dependency 'weekly_snippets'
  s.add_runtime_dependency 'hash-joiner'
  s.add_runtime_dependency 'lambda_map_reduce'
  s.add_development_dependency 'go_script', '~> 0.1'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'about_yml'
end
