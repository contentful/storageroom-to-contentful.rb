require 'spec_helper'
require 'storage_room_exporter'

describe StorageRoomExporter do

  context 'collections' do
    it 'export_collections' do
      vcr('collection/export_collections') do
        # credentials = YAML.load_file('spec/support/credentials_spec.yaml')
        # StorageRoomExporter.stub(:credentials).and_return(credentials)
        collections = subject.export_collections
        expect(collections.count).to eq 4
        expect(collections.first['@type']).to eq 'Collection'
      end
    end

    it 'get_request ' do
      vcr('collection/get_request') do
        st_object = StorageRoomExporter.new
        credentials = YAML.load_file('spec/support/credentials_spec.yaml')
        st_object.credentials.stub(:yaml_file).and_return(credentials)
        request = subject.send(:get_request, 'collections')
      end
    end
  end
end
