require 'contentful/management'
require 'storage_room'
require 'pry'
require 'fileutils'
require_relative 'storage_room_exporter'
require_relative 'contentful_importer'

class Migrator

  attr_reader :storage_room_exporter, :contentful_importer

  def run
    puts <<-eoruby, __FILE__
Actions:
  1. Download all data from StorageRoom to JSON file
  2. Import data to Contentful.
  3. Dump entries from Storageroom.
    eoruby
    action_choice = gets.to_i
    case action_choice
      when 1
        storage_room_exporter.export_collections
      when 2
        contentful_importer.create_space
        contentful_importer.import_content_types
      when 3
        storage_room_exporter.export_entries
    end
  end

  def storage_room_exporter
    @storage_room_exporter ||= StorageRoomExporter.new
  end

  def contentful_importer
    @contentful_importer ||= ContentfulImporter.new
  end
end

Migrator.new.run



