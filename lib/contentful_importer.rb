class ContentfulImporter

  ACCESS_TOKEN = 'e548877d1c317ee58e5710c793bd2d92419149b1e3c50d47755a19a5deadda00'
  ORGANIZATION_ID = '1EQPR5IHrPx94UY4AViTYO'
  COLLECTIONS_DATA_DIR = 'data/collections'

  attr_reader :space

  def initialize
    Contentful::Management::Client.new(ACCESS_TOKEN)
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
    end
  end

  private

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
      field.type = 'Link'
      field.link_type = params['link_type']
    end
  end

end