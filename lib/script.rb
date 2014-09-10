require 'contentful/management'
require 'storage_room'
require 'pry'
require 'pp'

ACCOUNT_ID = '4d13574cba05613d25000004'
APPLICATION_API_KEY = 'DZHpRbsJ7VgFXhybKWmT'

StorageRoom.authenticate(ACCOUNT_ID, APPLICATION_API_KEY)

collections = StorageRoom::Collection.all
collections.instance_variable_get("@_attributes")['resources'].each do |collection|
  json_collection = JSON.parse collection.to_json
  File.open("collection_#{collection.name.downcase}.json", "w").write(JSON.pretty_generate(json_collection))
end

