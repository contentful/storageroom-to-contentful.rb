# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'storageroom-to-contentful'
  spec.version       = Version::VERSION
  spec.authors       = ['Andreas Tiefenthaler']
  spec.email         = ['at@an-ti.eu']
  spec.description   = 'Import data from StorageRoom to Contentful'
  spec.summary   = 'Import data from StorageRoom to Contentful'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables    << 'storageroom-to-contentful'
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'http', '~> 0.6'
  spec.add_dependency 'multi_json', '~> 1'
  spec.add_dependency 'contentful-management', '~> 0.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'

end
