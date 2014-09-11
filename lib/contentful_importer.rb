class ContentfulImporter

  ACCESS_TOKEN = 'e548877d1c317ee58e5710c793bd2d92419149b1e3c50d47755a19a5deadda00'
  ORGANIZATION_ID = '1EQPR5IHrPx94UY4AViTYO'
  COLLECTIONS_DATA_DIR = 'data/collections'
  ENTRIES_DATA_DIR = 'data/entries'

  attr_reader :space, :content_type

  def initialize
    Contentful::Management::Client.new(ACCESS_TOKEN)
  end

  def content_type(content_type_id, space_id)
    @content_type ||= Contentful::Management::ContentType.find(space_id, content_type_id)
  end

  def create_space
    # puts "Write your contentful name of space:"
    # name_space = gets
    # @space = Contentful::Management::Space.create(name: name_space, organization_id: ORGANIZATION_ID)
    @space = Contentful::Management::Space.find('ene4qtp2sh7u')
  end

  def import_content_types
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))['collection']
      content_type = space.content_types.create(name: collection_attributes['entry_type'])
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
      entry_attrbiutes = JSON.parse(File.read(file_path))['entry']
      entry_params = {}
      entry_attrbiutes.each do |attr, value|
        entry_params[attr.to_sym] = value
      end
      collection_name = file_path.match(/data\/entries\/(.*)\/.*/)[1]
      content_type_id = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))['content_type_id']
      space_id = JSON.parse(File.read("#{COLLECTIONS_DATA_DIR}/#{collection_name}.json"))['space_id']
      content_type(content_type_id, space_id).entries.create(entry_params)
    end
  end

  private

  def add_content_type_id_to_file(content_type_id, space_id, file_path)
    content_type = JSON.parse(File.read(file_path))
    File.open(file_path, 'w').write(format_json(content_type.merge(content_type_id: content_type_id, space_id: space_id)))
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
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
      field.type = params['link'].presence || 'Link'
      field.link_type = params['link_type']
    end
  end

end