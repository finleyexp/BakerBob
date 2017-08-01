# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drotto/version'

Gem::Specification.new do |spec|
  spec.name = 'bakerbob'
  spec.version = BakerBob::VERSION
  spec.authors = ['Monique Finley']
  spec.email = ['mfinley@finleyexperience.com']

  spec.summary = %q{Pay-to-play voting bot.}
  spec.description = %q{Where you bid for votes/}
  spec.homepage = 'https://github.com/finleyexp/bakerbob'
  spec.license = 'CC BY-SA'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 12.0.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-line'
  spec.add_development_dependency 'minitest-proveit'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'faraday'
  spec.add_development_dependency 'typhoeus'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.5.2'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'delorean'

  spec.add_dependency 'radiator'
  spec.add_dependency 'awesome_print'
  spec.add_dependency 'rdiscount'
end
