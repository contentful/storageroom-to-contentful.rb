require 'spec_helper'
require 'storage_room_exporter'
require 'contentful/management'

describe StorageRoomExporter do

  before do
    StorageRoomExporter.any_instance.stub(:credentials).and_return(YAML.load_file('spec/support/credentials_spec.yaml'))
  end

  context 'collections' do
    it 'export_collections' do
      vcr('collection/export_collections') do
        collections = subject.export_collections
        expect(collections.count).to eq 4
        expect(collections.first['@type']).to eq 'Collection'
      end
    end

    it 'get_request ' do
      vcr('collection/get_request') do
        request = subject.send(:get_request, 'collections')
        expect(request['array']['resources'].count).to eq 4
        expect(request['array']['resources'].first['@type']).to eq 'Collection'
        expect(request['array']['resources'].first['entry_type']).to eq 'Announcement'
      end
    end
    it 'collection_id ' do
      collection = JSON.parse(File.read('spec/support/data/collections/codequest.json'))
      collection_id = subject.send(:collection_id, collection)
      expect(collection_id).to eq '540d6d001e29fa3541000d2d'
    end

  end
  context 'entries' do
    it 'export_entries' do
      vcr('entries/export_entries') do
        entries = subject.export_entries
        request = subject.send(:entries, entries.first)
        expect(request.count).to eq 8
        expect(request.first['@type']).to eq 'Announcement'
        expect(request.first['text']).to eq 'Welcome to our app. Try clicking around.'
      end
    end

    it 'entries' do
      vcr('entries/entries') do
        collection = JSON.parse(File.read('spec/support/data/collections/codequest.json'))
        request = subject.send(:entries, collection)
        expect(request.count).to eq 2
        expect(request.first['@type']).to eq 'Codequest'
        expect(request.first['name']).to eq 'Test'
        expect(request.first['number']).to eq 11
      end
    end
  end
end
