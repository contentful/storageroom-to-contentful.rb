require 'yaml'
require 'uri'
require 'net/http'
require_relative 'shared_methods'
class StorageRoomExporter
  include SharedMethods
  COLLECTIONS_DATA_DIR = "#{$APP_ROOT}/data/collections"
  ENTRIES_DATA_DIR = "#{$APP_ROOT}/data/entries"
  STORAGE_ROOM_URL = 'http://api.storageroomapp.com/accounts/'

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
        input_type = field['input_type']
        case input_type
          when 'file'
          when 'association_field'
          when 'json_field'
          when 'radio'
          when 'text_field'
          when 'array_field'
        end
      end
    end
  end

  private

  def save_to_file(dir, file_name, json)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    File.open("#{dir}/#{file_name.downcase}.json", 'w') { |file| file.write(json) }
  end

  def collections
    @collections ||= get_request('collections')['array']['resources']
  end

  def get_request(path)
    uri = URI.parse("#{STORAGE_ROOM_URL}#{credentials['ACCOUNT_ID']}/#{path}.json?auth_token=#{credentials['APPLICATION_API_KEY']}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code == '200'
      JSON.parse(response.body)
    else
      fail "ERROR: #{uri.inspect}"
    end
  end

  def collection_id(collection)
    File.basename(collection['@url'])
  end

  def entries(collection)
    get_request("collections/#{collection_id(collection)}/entries")['array']['resources']
  end
end
