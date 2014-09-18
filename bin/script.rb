#!/usr/bin/ruby

require 'yaml'

APP_ROOT = File.expand_path('../../', __FILE__)
COLLECTIONS_DATA_DIR = "#{APP_ROOT}/data/collections"
ENTRIES_DATA_DIR = "#{APP_ROOT}/data/entries"
STORAGE_ROOM_URL = 'http://api.storageroomapp.com/accounts/'
yaml_path = File.expand_path('../../credentials.yaml', __FILE__)
CREDENTIALS = YAML.load_file(yaml_path)

load 'lib/migrator.rb'