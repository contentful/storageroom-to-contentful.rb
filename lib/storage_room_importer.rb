class StorageRoomImporter

  ACCOUNT_ID = '4d13574cba05613d25000004'
  APPLICATION_API_KEY = 'HKqZqeesYzwmB3DC6eeZ'
  DATA_DIR = 'data'
  COLLECTIONS_DATA_DIR = "#{DATA_DIR}/collections"
  ENTRIES_DATA_DIR = "#{DATA_DIR}/entries"

  attr_reader :collections

  def authenticate
    StorageRoom.authenticate(ACCOUNT_ID, APPLICATION_API_KEY)
  end

  def import_collections
    collections.instance_variable_get(:@_attributes)['resources'].each do |collection|
      save_to_file(COLLECTIONS_DATA_DIR, collection.name, format_json(collection))
    end
  end

  def import_entries
    collections.instance_variable_get(:@_attributes)['resources'].each do |collection|
      collection.entries.instance_variable_get(:@_attributes)['resources'].each do |entry|
        save_to_file("#{ENTRIES_DATA_DIR}/#{collection.name.name.downcase}", entry.name, format_json(entry))
      end
    end
  end

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

  def save_to_file(dir, file_name, json)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    File.open("#{dir}/#{file_name.downcase}.json", 'w').write(json)
  end

  def collections
    @collections ||= StorageRoom::Collection.all
  end

  # Dir.glob("#{COLLECTIONS_DATA_DIR}/*json") do |file_path|
  #   collection_file = JSON.parse(File.read(file_path))
  #   collection_attribute = collection_file['collection']
  #   entry_name = collection_attribute['entry_type']
  #   collection = StorageRoom::Collection.find(collection_attribute['id'])
  #   entries = collection.entries
  #   entries.instance_variable_get("@_attributes")['resources'].each do |entry|
  #     json_entry = JSON.parse entry.to_json
  #     FileUtils.mkdir_p "data/entries/#{entry_name}"
  #     File.open("data/entries/#{entry_name}/#{entry.name}.json", "w").write(JSON.pretty_generate(json_entry))
  #   end
  # end

end