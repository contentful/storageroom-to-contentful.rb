require 'uri'
require 'net/http'

class StorageRoomExporter

  attr_reader :collections

  def export_collections
    puts 'Exporting collections:'
    collections.each do |collection|
      puts collection['name']
      save_to_file(COLLECTIONS_DATA_DIR, collection['entry_type'], format_json(collection))
    end
  end

  def export_entries
    collections.each do |collection|
      puts "Exporting entries for: #{collection['name']}"
      entries(collection).each do |entry|
        entry_id = File.basename(entry['@url'])
        save_to_file("#{ENTRIES_DATA_DIR}/#{collection['entry_type'].downcase}", "#{entry_id}", format_json(entry))
      end
    end
  end

  def mapping_collections_input_types
    Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
      collection_attributes = JSON.parse(File.read(file_path))
      collection_attributes['fields'].each do |field|
        case field['input_type']
          when 'select'
            field['input_type'] = 'Symbol'
          when 'date_picker'
            field['input_type'] = 'Date'
          when 'time_picker'
            field['input_type'] = 'Date'
          when 'location'
            field['input_type'] = 'Location'
          when 'file'
            field['input_type'] = 'Asset'
          when 'json_field'
            field['input_type'] = 'Object'
          when 'radio'
            field['input_type'] = 'Boolean'
          when 'array_field'
            field['input_type'] = 'Array'
            field['link'] = 'Symbol'
          when 'text_field'
            mapping_text_fields(field)
          when 'association_field'
            mapping_association_field(field)
        end
      end
      File.open(file_path, 'w') { |file| file.write(format_json(collection_attributes)) }
    end
  end

  private

  def mapping_association_field(field)
    if field['@type'] == 'OneAssociationField'
      field['input_type'] = 'Entry'
    else
      field['input_type'] = 'Array'
      field['link_type'] = 'Entry'
    end
  end

  def mapping_text_fields(field)
    case field['@type']
      when 'StringField'
        field['input_type'] = 'Text'
      when 'IntegerField'
        field['input_type'] = 'Integer'
      when 'FloatField'
        field['input_type'] = 'Number'
    end
  end

  def save_to_file(dir, file_name, json)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    File.open("#{dir}/#{file_name.downcase}.json", 'w') { |file| file.write(json) }
  end

  def collections
    @collections ||= get_request('collections')['array']['resources']
  end

  def get_request(path)
    uri = URI.parse("#{STORAGE_ROOM_URL}#{CREDENTIALS['ACCOUNT_ID']}/#{path}.json?auth_token=#{CREDENTIALS['APPLICATION_API_KEY']}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code == '200'
      JSON.parse(response.body)
    else
      fail "ERROR: #{uri.inspect}"
    end
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

  def collection_id(collection)
    File.basename(collection['@url'])
  end

  def entries(collection)
    get_request("collections/#{collection_id(collection)}/entries")['array']['resources']
  end

end
