class StorageRoomExporter

  ACCOUNT_ID = '4d13574cba05613d25000004'
  APPLICATION_API_KEY = 'HKqZqeesYzwmB3DC6eeZ'
  COLLECTIONS_DATA_DIR = 'data/collections'
  ENTRIES_DATA_DIR = 'data/entries'

  attr_reader :collections

  def initialize
    StorageRoom.authenticate(ACCOUNT_ID, APPLICATION_API_KEY)
  end

  def export_collections
    puts 'Importing collections:'
    collections.each do |collection|
      puts collection.name
      save_to_file(COLLECTIONS_DATA_DIR, collection.name, format_json(collection))
    end
  end

  def export_entries
    collections.each do |collection|
      puts "Importing entries for: #{collection.name}"
      entries(collection).each_with_index do |entry, i|
        save_to_file("#{ENTRIES_DATA_DIR}/#{collection.entry_type.downcase}", "#{collection.entry_type}_#{i}", format_json(entry))
      end
    end
  end

  private

  def format_json(item)
    JSON.pretty_generate(JSON.parse(item.to_json))
  end

  def save_to_file(dir, file_name, json)
    FileUtils.mkdir_p dir unless File.directory?(dir)
    File.open("#{dir}/#{file_name.downcase}.json", 'w').write(json)
  end

  def collections
    @collections ||= StorageRoom::Collection.all.instance_variable_get(:@_attributes)['resources']
  end

  def entries(collection)
    collection.entries.instance_variable_get(:@_attributes)['resources']
  end

end