require 'spec_helper'
require 'storage_room_exporter'
require 'contentful/management'
require 'i18n'
require 'active_support/lazy_load_hooks'

describe StorageRoomExporter do

  before do
    stub_const('StorageRoomExporter::CONTENTFUL_TYPES', %w(Text Integer Number Boolean Symbol Array Entry Asset Date Location Object))
    stub_const('StorageRoomExporter::STORAGE_ROOM_URL', 'http://api.storageroomapp.com/accounts/')
    stub_const('StorageRoomExporter::COLLECTIONS_DATA_DIR', 'spec/support/data/collections')
    stub_const('StorageRoomExporter::ENTRIES_DATA_DIR', 'spec/support/data/entries')
    stub_const('StorageRoomExporter::CREDENTIALS', YAML.load_file('spec/support/credentials_spec.yaml'))
    stub_const('APP_ROOT', File.expand_path('../../../', __FILE__))
    I18n.load_path << "#{APP_ROOT}/contenftul_fields_types.yml"
  end

  context 'collections' do
    it 'export_collections' do
      vcr('collection/export_collections') do
        StorageRoomExporter.any_instance.stub(:save_to_file)
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
        StorageRoomExporter.any_instance.stub(:save_to_file)
        entries = subject.export_entries
        request = subject.send(:entries, entries.first)
        expect(request.count).to eq 8
        expect(request.first['@type']).to eq 'Announcement'
        expect(request.first['text']).to eq 'Welcome to our app. Try clicking around.'
      end
    end

    it 'get all entries from storageroom' do
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

  it 'save_to_file' do
    entry = File.read('spec/support/data/entries/codequest/540d6d961e29fa3559000d0d.json')
    subject.send(:save_to_file, 'spec/support/data', 'save_to_file', entry)
  end

  it 'mapping_collections_input_types' do
    stub_const('StorageRoomExporter::COLLECTIONS_DATA_DIR', 'spec/support/data/convert/mapping')
    subject.mapping_collections_input_types
  end


  context 'translate input types' do
    it 'StringField and text_field' do
      field = {:@type => 'StringField', :input_type => 'text_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Text'
    end
    it 'IntegerField and text_field' do
      field = {:@type => 'IntegerField', :input_type => 'text_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Integer'
    end
    it 'FloatFied and text_field' do
      field = {:@type => 'FloatField', :input_type => 'text_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Number'
    end
    it 'Location and text_field' do
      field = {:@type => 'Location', :input_type => 'location'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Location'
    end
    it 'BooleanField and radio' do
      field = {:@type => 'BooleanField', :input_type => 'radio'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Boolean'
    end
    it 'Select' do
      field = {:@type => 'StringField', :input_type => 'select'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Symbol'
    end
    it 'Image and File' do
      field = {:@type => 'File', :input_type => 'file'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Asset'
    end

    it 'OneAssociationField' do
      field = {:@type => 'OneAssociationField', :input_type => 'association_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Entry'
    end

    it 'OneAssociationField' do
      field = {:@type => 'ManyAssociationField', :input_type => 'association_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Array'
    end

    it 'Array_field' do
      field = {:@type => 'ManyAssociationField', :input_type => 'array_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Array'
    end

    it 'Json_field' do
      field = {:@type => 'JsonField', :input_type => 'json_field'}
      subject.send(:translate_input_type, field)
      expect(field[:input_type]).to eq 'Object'
    end

  end

end
