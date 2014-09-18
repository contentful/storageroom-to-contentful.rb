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
        field_type = field['input_type']
        field['input_type'] = begin
          I18n.t! "fields.input_type.#{field['@type']}.#{field_type}"
        rescue I18n::MissingTranslationData
          I18n.t "fields.input_type.#{field_type}"
        end
        mapping_array_type(field)
      end
      File.open(file_path, 'w') { |file| file.write(format_json(collection_attributes)) }
    end
  end

  private

  def mapping_array_type(field)
    if field['@type'] == 'ManyAssociationField'
      field['link_type'] = 'Entry'
    elsif field['@type'] == 'ArrayField'
      field['link'] = 'Symbol'
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
