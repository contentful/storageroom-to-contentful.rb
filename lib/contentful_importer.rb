require_relative 'mime_content_type'
require 'contentful/management'
require_relative 'shared_methods'

class ContentfulImporter
  include SharedMethods
  COLLECTIONS_DATA_DIR = "#{$APP_ROOT}/data/collections"
  ENTRIES_DATA_DIR = "#{$APP_ROOT}/data/entries"
  attr_reader :space

  def initialize
    Contentful::Management::Client.new(credentials['ACCESS_TOKEN'])
  end

  def create_space
    puts 'Write your contentful name of space:'
    name_space = gets
    @space = Contentful::Management::Space.create(name: name_space, organization_id: credentials['ORGANIZATION_ID'])
  end

  def import_content_types
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      content_type = space.content_types.create(name: collection_attributes['entry_type'], description: collection_attributes['note'])
      puts "Importing content_type: #{content_type.name}"
      create_content_type_fields(collection_attributes, content_type)
      create_content_type_webhooks(collection_attributes['webhook_definitions'], content_type.space.id)
      add_content_type_id_to_file(collection_attributes, content_type.id, content_type.space.id, file_path)
      active_content_type(content_type.activate)
    end
  end

  def import_entries
    Dir.glob("#{ENTRIES_DATA_DIR}/*") do |dir_path|
      collection_name = File.basename(dir_path)
      puts "Importing entries for #{collection_name}."
      collection_attributes = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))
      content_type_id = collection_attributes['content_type_id']
      space_id = collection_attributes['space_id']
      import_entry(content_type_id, dir_path, space_id)
    end
  end

  def publish_all_entries
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |dir_path|
      collection_name = File.basename(dir_path,'.json')
      puts "Publish entries for #{collection_name}."
      collection_attributes = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))
      Contentful::Management::Space.find(collection_attributes['space_id']).entries.all.each do |entry|
        puts "Publish an entry with ID #{entry.id}."
        entry_publish_status(entry.publish)
      end
    end
  end

  def find_symbol_params_in_collection
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      collection_attributes['fields'].each do |field|
        find_symbol_attribute(collection_attributes, field)
      end
    end
  end

  private

  def find_symbol_attribute(collection_attributes, field)
    convert_symbol_value(collection_attributes, field) if field['input_type'] == 'Symbol'
  end

  def convert_symbol_value(collection_attributes, field)
    select_id = field['identifier']
    Dir.glob("#{ENTRIES_DATA_DIR}/#{collection_attributes['entry_type'].downcase}/*json") do |entry_path|
      convert_params_from_symbol_in_entry_file(entry_path, select_id)
    end
  end

  def convert_params_from_symbol_in_entry_file(entry_path, select_id)
    entry_attributes = JSON.parse(File.read(entry_path))
    value_of_select = entry_attributes["#{select_id}"]
    parse_symbol_value_to_string(entry_path, value_of_select, select_id, entry_attributes) unless value_of_select.is_a? String
  end

  def parse_symbol_value_to_string(entry_path, value_of_select, select_id, entry_attributes)
    entry_attributes["#{select_id}"] = value_of_select.to_s
    File.open(entry_path, 'w') do |file|
      file.write(format_json(entry_attributes))
    end
  end

  def create_content_type_fields(collection_attributes, content_type)
    collection_attributes['fields'].each do |field|
      create_field(field, content_type)
    end
  end

  def create_content_type_webhooks(params, space_id)
    if params
      params.each do |webhook|
        Contentful::Management::Webhook.create(space_id, url: webhook['url'])
      end
    end
  end

  def import_entry(content_type_id, dir_path, space_id)
    Dir.glob("#{dir_path}/*.json") do |file_path|
      entry_attributes = JSON.parse(File.read(file_path))
      entry_id = File.basename(file_path, '.json')
      puts "Creating entry: #{entry_id}."
      entry_params = create_entry_parameters(content_type_id, entry_attributes, space_id)
      entry = content_type(content_type_id, space_id).entries.create(entry_params.merge(id: entry_id))
      import_status(entry)
    end
  end

  def create_entry_parameters(content_type_id, entry_attributes, space_id)
    entry_attributes.each_with_object({}) do |(attr, value), entry_params|
      next if attr.start_with?('@')
      entry_params[attr.to_sym] = if value.is_a? Hash
                                    parse_attributes_from_hash(value, space_id, content_type_id)
                                  elsif value.is_a? Array
                                    parse_attributes_from_array(value, space_id, content_type_id)
                                  else
                                    value
                                  end
    end
  end

  def parse_attributes_from_hash(params, space_id, content_type_id)
    type = params['@type']
    if type
      case type
        when 'Location'
          create_location_file(params)
        when 'File'
          create_asset(space_id, params)
        when 'Image'
          create_asset(space_id, params)
        else
          create_entry(params, space_id, content_type_id)
      end
    else
      params
    end
  end

  def parse_attributes_from_array(params, space_id, content_type_id)
    params.each_with_object([]) do |attr, array_attributes|
      array_attributes << if attr['@type']
                            create_entry(attr, space_id, content_type_id)
                          else
                            attr
                          end
    end
  end

  def import_status(entry)
    if entry.is_a? Contentful::Management::Entry
      puts 'Imported successfully!'
    else
      puts "### Failure! - #{entry.message} ###"
    end
  end

  def content_type(content_type_id, space_id)
    Contentful::Management::ContentType.find(space_id, content_type_id)
  end

  def add_content_type_id_to_file(collection, content_type_id, space_id, file_path)
    File.open(file_path, 'w') { |file| file.write(format_json(collection.merge(content_type_id: content_type_id, space_id: space_id))) }
  end

  def create_entry(params, space_id, content_type_id)
    content_type = Contentful::Management::ContentType.find(space_id, content_type_id)
    content_type.entries.new.tap do |entry|
      entry.id = get_id(params)
    end
  end

  def get_id(params)
    File.basename(params['@url'] || params['url'])
  end

  def create_asset(space_id, params)
    asset_file = Contentful::Management::File.new.tap do |file|
      file.properties[:contentType] = file_content_type(params)
      file.properties[:fileName] = 'fix_this_name'
      file.properties[:upload] = params['@url']
    end
    space = Contentful::Management::Space.find(space_id)
    space.assets.create(title: 'StorageRoom file', description: 'test', file: asset_file).process_file
  end

  def create_location_file(params)
    Contentful::Management::Location.new.tap do |file|
      file.lat = params['lat']
      file.lon = params['lng']
    end
  end

  def create_field(field, content_type)
    field_params = {id: field['identifier'], name: field['name'], required: field['required']}
    field_params.merge!(additional_field_params(field))
    puts "Creating field: #{field_params[:type]}"
    content_type.fields.create(field_params)
  end

  def active_content_type(content_type)
    if content_type.is_a? Contentful::Management::ContentType
      puts 'Successfully activated!'
    else
      puts "### Failure! - #{content_type.message} ! ###"
    end
  end

  def entry_publish_status(entry)
    if entry.is_a? Contentful::Management::Entry
      puts 'Successfully published!'
    else
      puts "### Failure! - #{entry.message} ! ###"
    end
  end

  def additional_field_params(field)
    field_type = field['input_type']
    if field_type == 'Entry' || field_type == 'Asset'
      {type: 'Link', link_type: field_type}
    elsif field_type == 'Array'
      {type: 'Array', items: create_array_field(field)}
    else
      {type: field_type}
    end
  end

  def file_content_type(params)
    MimeContentType::EXTENSION_LIST[File.extname(params['@url'])]
  end

  def create_array_field(params)
    Contentful::Management::Field.new.tap do |field|
      field.type = params['link'] || 'Link'
      field.link_type = params['link_type']
    end
  end

end
