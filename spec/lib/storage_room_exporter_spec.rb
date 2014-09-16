require 'spec_helper'
require 'storage_room_exporter'

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
      end
    end
  end
end
