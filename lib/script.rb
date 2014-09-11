require 'contentful/management'
require 'storage_room'
require 'pry'
require 'fileutils'

CONTENTFUL_ACCESS_TOKEN = 'e548877d1c317ee58e5710c793bd2d92419149b1e3c50d47755a19a5deadda00'
CONTENTFUL_ORGANIZATION_ID = '1EQPR5IHrPx94UY4AViTYO'

puts "Actions:\n 1. Download all data from StorageRoom to JSON file\n 2. Import data to Contentful.\n 3. Dump entries from Storageroom."
user_action = gets.to_i

def authenticate_contentful
  Contentful::Management::Client.new(CONTENTFUL_ACCESS_TOKEN)
end

def create_contentful_space
  # puts "Write your contentful name of space:"
  # name_space = gets
  # @space = Contentful::Management::Space.create(name: name_space, organization_id: CONTENTFUL_ORGANIZATION_ID)
  @space = Contentful::Management::Space.find('ene4qtp2sh7u')
end

def import_collection_to_contentful
  $dir_target = "#{Dir.pwd}/data"
  Dir.glob("#{$dir_target}/collections/*json") do |file_path|
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


# def import_assets_to_contentful
#   Dir.glob("#{$dir_target}/entries/*json") do |file_path|
#     collection_file = JSON.parse(File.read(file_path))
#     collection_attribute = collection_file['collection']
#     fields = collection_attribute['fields']
#     fields.each do |field|
#       unless field['input_type'] == 'Asset'
#         @space.assets.create()
#       end
#     end
#   end
# end

def create_field(params)
  field = Contentful::Management::Field.new
  field.type = 'Link'
  field.link_type = params['link_type']
  field
end

case user_action
  when 1
    import_collections
  when 2
    create_contentful_space
    import_collection_to_contentful
  when 3
    import_entries
end
