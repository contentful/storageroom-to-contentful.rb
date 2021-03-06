require_relative 'mime_content_type'
require 'contentful/management'

class ContentfulImporter
  ENTRIES_IDS = []
  attr_reader :space

  def initialize
    Contentful::Management::Client.new(CREDENTIALS['ACCESS_TOKEN'])
  end

  def test_credentials
    test_contetful_credentials
    test_storageroom_credentials
  end

  def test_contetful_credentials
    space = Contentful::Management::Space.all
    if space.is_a? Contentful::Management::Array
      puts 'Contentful Management API credentials: OK'
    end
  rescue NoMethodError => e
    puts 'Contentful Management API credentials: INVALID (check README)'
  end

  def test_storageroom_credentials
    request = StorageRoomExporter.new.send(:get_request, 'collections')
    if request.is_a? Hash
      puts 'StorageRoom API credentials: OK'
    end
  rescue RuntimeError => e
    puts 'StorageRoom API credentials: INVALID (check README)'
    puts e
  end

  def create_space
    puts 'Name for a new created space on Contentful:'
    name_space = gets.strip
    @space = Contentful::Management::Space.create(name: name_space, organization_id: CREDENTIALS['ORGANIZATION_ID'])
  end

  def import_content_types
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      content_type = create_new_content_type(collection_attributes)
      puts "Importing content_type: #{content_type.name}"
      create_content_type_fields(collection_attributes, content_type)
      create_content_type_webhooks(collection_attributes['webhook_definitions'], content_type.space.id)
      add_content_type_id_to_file(collection_attributes, content_type.id, content_type.space.id, file_path)
      active_status(content_type.activate)
    end
  end

  def map_entries_ids
    Dir.glob("#{ENTRIES_DATA_DIR}/**/*json") do |dir_path|
      ENTRIES_IDS << File.basename(dir_path, '.json')
    end
  end

  def import_entries
    map_entries_ids
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
      collection_name = File.basename(dir_path, '.json')
      puts "Publish entries for #{collection_name}."
      collection_attributes = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))
      Contentful::Management::Space.find(get_space_id(collection_attributes)).entries.all.each do |entry|
        puts "Publish an entry with ID #{entry.id}."
        active_status(entry.publish)
      end
    end
  end

  def find_symbol_type_in_collection
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      collection_attributes['fields'].each do |field|
        find_symbol_attribute(collection_attributes, field)
      end
    end
  end

  private

  def get_space_id(collection)
    collection['space_id']
  end

  def find_symbol_attribute(collection_attributes, field)
    find_symbol_type_in_entry(collection_attributes, field) if field['input_type'] == 'Symbol'
  end

  def find_symbol_type_in_entry(collection_attributes, field)
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
    fields = collection_attributes['fields'].each_with_object([]) do |field, fields|
      fields << create_field(field)
    end
    content_type.fields = fields
    content_type.save
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
      entry_param = if value.is_a? Hash
                      parse_attributes_from_hash(value, space_id, content_type_id)
                    elsif value.is_a? Array
                      parse_attributes_from_array(value, space_id, content_type_id)
                    else
                      value
                    end
      entry_params[attr.to_sym] = entry_param unless validate_param(entry_param)
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
      value = if attr['@type']
                create_entry(attr, space_id, content_type_id)
              else
                attr
              end
      array_attributes << value unless value.nil?
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

  def create_new_content_type(collection_attributes)
    space.content_types.new.tap do |content_type|
      content_type.name = collection_attributes['entry_type']
      content_type.description = collection_attributes['note']
    end
  end

  def add_content_type_id_to_file(collection, content_type_id, space_id, file_path)
    File.open(file_path, 'w') { |file| file.write(format_json(collection.merge(content_type_id: content_type_id, space_id: space_id))) }
  end

  def create_entry(params, space_id, content_type_id)
    entry_id = get_id(params)
    if ENTRIES_IDS.include? entry_id
      content_type = Contentful::Management::ContentType.find(space_id, content_type_id)
      content_type.entries.new.tap do |entry|
        entry.id = entry_id
      end
    end
  end

  def get_id(params)
    File.basename(params['@url'] || params['url'])
  end

  def create_asset(space_id, params)
    asset_file = Contentful::Management::File.new.tap do |file|
      file.properties[:contentType] = file_content_type(params)
      file.properties[:fileName] = params['@type']
      file.properties[:upload] = params['@url']
    end
    space = Contentful::Management::Space.find(space_id)
    space.assets.create(title: "#{params['@type']}", description: '', file: asset_file).process_file
  end

  def create_location_file(params)
    Contentful::Management::Location.new.tap do |file|
      file.lat = params['lat']
      file.lon = params['lng']
    end
  end

  def create_field(field)
    field_params = {id: field['identifier'], name: field['name'], required: field['required']}
    field_params.merge!(additional_field_params(field))
    puts "Creating field: #{field_params[:type]}"
    create_content_type_field(field_params)
  end

  def create_content_type_field(field_params)
    Contentful::Management::Field.new.tap do |field|
      field.id = field_params[:id]
      field.name = field_params[:name]
      field.type = field_params[:type]
      field.link_type = field_params[:link_type]
      field.required = field_params[:required]
      field.items = field_params[:items]
    end
  end

  def active_status(ct_object)
    if ct_object.is_a? Contentful::Management::Error
      puts "### Failure! - #{ct_object.message} ! ###"
    else
      puts 'Successfully activated!'
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

  def validate_param(param)
    if param.is_a? Array
      param.empty?
    else
      param.nil?
    end
  end

  def file_content_type(params)
    MimeContentType::EXTENSION_LIST[File.extname(params['@url'])]
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

  def create_array_field(params)
    Contentful::Management::Field.new.tap do |field|
      field.type = params['link'] || 'Link'
      field.link_type = params['link_type']
    end
  end

end
