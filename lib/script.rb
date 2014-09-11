require 'contentful/management'
require 'storage_room'
require 'pry'
require 'fileutils'

CONTENTFUL_ACCESS_TOKEN = 'e548877d1c317ee58e5710c793bd2d92419149b1e3c50d47755a19a5deadda00'
CONTENTFUL_ORGANIZATION_ID = '1EQPR5IHrPx94UY4AViTYO'

ACCOUNT_ID = '4d13574cba05613d25000004'
APPLICATION_API_KEY = 'HKqZqeesYzwmB3DC6eeZ'

Contentful::Management::Client.new(CONTENTFUL_ACCESS_TOKEN)
StorageRoom.authenticate(ACCOUNT_ID, APPLICATION_API_KEY)

puts "Actions:\n 1. Download all data from StorageRoom to JSON file\n 2. Import data to Contentful."
user_action = gets.to_i

def create_contentful_space
  # puts "Write your contentful name of space:"
  # name_space = gets
  # @space = Contentful::Management::Space.create(name: name_space, organization_id: CONTENTFUL_ORGANIZATION_ID)
  @space = Contentful::Management::Space.find('ene4qtp2sh7u')
end

def dump_collections_from_storageroom
  collections = StorageRoom::Collection.all
  collections.instance_variable_get("@_attributes")['resources'].each do |collection|
    json_collection = JSON.parse collection.to_json
    FileUtils.mkdir_p 'data/collections' unless File.directory?('data/collections')
    File.open("data/collections/collection_#{collection.name.downcase}.json", "w").write(JSON.pretty_generate(json_collection))
  end
end

def import_collection_to_contentful
  $dir_target = "#{Dir.pwd}/data/collections"
  Dir.glob("#{$dir_target}/*json") do |file_path|
    collection_file = JSON.parse(File.read(file_path))
    collection_attribute = collection_file['collection']
    content_type = @space.content_types.create(name: collection_attribute['entry_type'])
    fields = collection_attribute['fields']
    fields.each do |field|
      field_type = field['input_type']
      if field_type == 'Entry' ||field_type == 'Asset'
        content_type.fields.create(id: field['identifier'], name: field['name'], type: 'Link', link_type: field['input_type'], required: field['required'])
      elsif field_type == 'Array'
        content_type.fields.create(id: field['identifier'], name: field['name'], type: 'Array', items: create_field(field))
      else
        content_type.fields.create(id: field['identifier'], name: field['name'], type: field['input_type'], required: field['required'])
      end
    end
  end
end



def create_field(params)
  field = Contentful::Management::Field.new
  field.type = 'Link'
  field.link_type = params['link_type']
  field
end

case user_action
  when 1
    dump_collections_from_storageroom
  when 2
    create_contentful_space
    import_collection_to_contentful
end