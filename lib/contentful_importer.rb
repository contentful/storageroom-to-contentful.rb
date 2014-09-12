class ContentfulImporter

  ACCESS_TOKEN = 'e548877d1c317ee58e5710c793bd2d92419149b1e3c50d47755a19a5deadda00'
  ORGANIZATION_ID = '1EQPR5IHrPx94UY4AViTYO'
  COLLECTIONS_DATA_DIR = 'data/collections'
  ENTRIES_DATA_DIR = 'data/entries'

  attr_reader :space

  def initialize
    Contentful::Management::Client.new(ACCESS_TOKEN)
  end

  def content_type(content_type_id, space_id)
    Contentful::Management::ContentType.find(space_id, content_type_id)
  end

  def create_space
    # puts "Write your contentful name of space:"
    # name_space = gets
    # @space = Contentful::Management::Space.create(name: name_space, organization_id: ORGANIZATION_ID)
    @space = Contentful::Management::Space.find('ene4qtp2sh7u')
  end

  def import_content_types
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      content_type = space.content_types.create(name: collection_attributes['entry_type'], description: collection_attributes['note'])
      puts "Importing content_type: #{content_type.name}"
      collection_attributes['fields'].each do |field|
        create_field(field, content_type)
      end
      add_content_type_id_to_file(content_type.id, content_type.space.id, file_path)
      content_type.activate
    end
  end

  def import_entries
    Dir.glob("#{ENTRIES_DATA_DIR}/**/*json") do |file_path|
      entry_attributes = JSON.parse(File.read(file_path))
      collection_name = file_path.match(/data\/entries\/(.*)\/.*/)[1]
      puts "Create entry for #{collection_name}."
      content_type_id = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))['content_type_id']
      space_id = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))['space_id']
      entry_params = {}
      entry_attributes.each do |attr, value|
        attr_value = if value.is_a? Hash
                       parse_attributes_from_hash(value, space_id, content_type_id)
                     elsif value.is_a? Array
                       parse_attributes_from_array(value, space_id, content_type_id)
                     else
                       value
                     end
        entry_params[attr.to_sym] = attr_value
      end
      entry_id = get_id(entry_attributes)
      content_type(content_type_id, space_id).entries.create(entry_params.merge(id: entry_id))
    end
  end

  def parse_attributes_from_hash(params, space_id, content_type_id)
    type = params['@type']
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
  end

  def parse_attributes_from_array(params, space_id, content_type_id)
    array_attributes = []
    params.each do |attr|
      array_attributes << if attr['@type']
                            create_entry(attr, space_id, content_type_id)
                          else
                            attr
                          end
    end
    array_attributes
  end

  private

  def add_content_type_id_to_file(content_type_id, space_id, file_path)
    content_type = JSON.parse(File.read(file_path))
    File.open(file_path, 'w').write(format_json(content_type.merge(content_type_id: content_type_id, space_id: space_id)))
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

  def create_entry(params, space_id, content_type_id)
    content_type = Contentful::Management::ContentType.find(space_id, content_type_id)
    entry = content_type.entries.new
    entry.id = get_id(params)
    entry
  end

  def get_id(params)
    File.basename(params['@url'] || params['url'])
  end

  def create_asset(space_id, params)
    file = Contentful::Management::File.new
    file.properties[:contentType] = 'image/png'
    file.properties[:fileName] = 'fix_this_name'
    file.properties[:upload] = params['@url']
    space = Contentful::Management::Space.find(space_id)
    space.assets.create(title: 'StorageRoom file', description: 'test', file: file).process_file
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

  def create_array_field(params)
    Contentful::Management::Field.new.tap do |field|
      field.type = params['link'] || 'Link'
      field.link_type = params['link_type']
    end
  end
end
