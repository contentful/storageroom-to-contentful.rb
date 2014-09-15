class StorageRoomExporter
  ACCOUNT_ID = '4d13574cba05613d25000004'
  APPLICATION_API_KEY = 'HKqZqeesYzwmB3DC6eeZ'
  COLLECTIONS_DATA_DIR = 'data/collections'
  ENTRIES_DATA_DIR = 'data/entries'
  STORAGE_ROOM_URL = 'http://api.storageroomapp.com/accounts/'

  attr_reader :collections

  def export_collections
    puts 'Exporting collections:'
    collections.each do |collection|
      puts collection['name']
      save_to_file(COLLECTIONS_DATA_DIR, collection['name'], format_json(collection))
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

  private

  def format_json(item)
    JSON.pretty_generate(item)
  end

  def save_to_file(dir, file_name, json)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    File.open("#{dir}/#{file_name.downcase}.json", 'w').write(json)
  end

  def collections
    @collections ||= get_request('collections')['array']['resources']
  end

  def get_request(path)
    uri = URI.parse("#{STORAGE_ROOM_URL}#{ACCOUNT_ID}/#{path}.json?auth_token=#{APPLICATION_API_KEY}")
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
