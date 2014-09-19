#!/usr/bin/ruby

require 'yaml'
require 'i18n'
require 'active_support/lazy_load_hooks'

APP_ROOT = File.expand_path('../../', __FILE__)
COLLECTIONS_DATA_DIR = "#{APP_ROOT}/data/collections"
ENTRIES_DATA_DIR = "#{APP_ROOT}/data/entries"
STORAGE_ROOM_URL = 'http://api.storageroomapp.com/accounts/'
CONTENTFUL_TYPES = %w(Text Integer Number Boolean Symbol Array Entry Asset Date Location Object)
yaml_path = File.expand_path('../../credentials.yaml', __FILE__)
CREDENTIALS = YAML.load_file(yaml_path)

I18n.load_path << "#{APP_ROOT}/contenftul_fields_types.yml"
I18n.enforce_available_locales = false

load 'lib/migrator.rb'