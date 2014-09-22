require_relative 'storage_room_exporter'
require_relative 'contentful_importer'
require 'contentful/management'
require 'fileutils'

class Migrator
  attr_reader :storage_room_exporter, :contentful_importer

  MESSAGE = <<-eoruby
Actions:
  1. Export data from StorageRoom to JSON files.
  2. Convert StorageRoom field types to Contentful.
  3. Import collections to Contentful.
  4. Import entries to Contentful.
  5. Publish all entries on Contentful.
-> Choose on of the options:
  eoruby

  def run
    puts MESSAGE
    action_choice = gets.to_i
    case action_choice
      when 1
        storage_room_exporter.export_collections
        storage_room_exporter.export_entries
      when 2
        storage_room_exporter.mapping_collections_input_types
      when 3
        contentful_importer.create_space
        contentful_importer.import_content_types
        contentful_importer.find_symbol_type_in_collection
      when 4
        contentful_importer.import_entries
      when 5
        contentful_importer.publish_all_entries
    end
  end

  def storage_room_exporter
    @storage_room_exporter ||= StorageRoomExporter.new
  end

  def contentful_importer
    @contentful_importer ||= ContentfulImporter.new
  end
end
