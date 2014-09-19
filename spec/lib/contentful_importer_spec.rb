require 'spec_helper'
require 'contentful_importer'
require 'contentful/management'
require 'yaml'

describe ContentfulImporter do

  before do
    stub_const('ContentfulImporter::STORAGE_ROOM_URL', 'http://api.storageroomapp.com/accounts/')
    stub_const('ContentfulImporter::COLLECTIONS_DATA_DIR', 'spec/support/data/collections')
    stub_const('ContentfulImporter::ENTRIES_DATA_DIR', 'spec/support/data/entries')
    stub_const('ContentfulImporter::CREDENTIALS', YAML.load_file('spec/support/credentials_spec.yaml'))
  end

  it 'create_space' do
    vcr('import/crate_space') do
      ContentfulImporter.any_instance.stub(:gets).and_return('test')
      space = subject.create_space
      expect(space.name).to eq 'test'
    end
  end

  it 'import_content_types' do
    vcr('import/content_types') do
      Contentful::Management::Client.new('<ACCESS_TOKEN>')
      space = Contentful::Management::Space.find('ksbb7zto17p9')
      ContentfulImporter.any_instance.stub(:space).and_return(space)
      subject.import_content_types
      content_type = space.content_types.all.first
      expect(content_type.name).to eq 'Codequest'
      expect(content_type.description).to eq 'Testing'
      expect(content_type.fields.count).to eq 13
      expect(content_type.active?).to be_truthy
    end
  end

  it 'import_entries' do
    vcr('import/entries') do
      subject.import_entries
      Contentful::Management::Client.new('<ACCESS_TOKEN>')
      space = Contentful::Management::Space.find('ksbb7zto17p9')
      entry = space.entries.find('540d6d961e29fa3559000d0d')
      expect(entry.id).to eq '540d6d961e29fa3559000d0d'
      expect(entry.number).to eq 11
      expect(entry.float1).to eq 1.1
      expect(entry.boolean).to eq true
      expect(entry.fields[:array].first).to eq 'some value'
      expect(entry.fields[:file]['sys']['id']).to eq 'LjiUYqF3k2SKkmEyQ2Yc0'
      expect(entry.fields[:image]['sys']['id']).to eq '6GGpDNJTRCYeOGyWKmUqky'
      expect(entry.fields[:entry]['sys']['id']).to eq '4d960919ba05617333000012'
      expect(entry.fields[:entries].first['sys']['id']).to eq '4e2ea1674d085d46a7000021'
    end
  end

  it 'find_symbol_params_in_collection' do
    stub_const('ContentfulImporter::COLLECTIONS_DATA_DIR', 'spec/support/data/convert/collections')
    stub_const('ContentfulImporter::ENTRIES_DATA_DIR', 'spec/support/data/convert/entries')
    ContentfulImporter.any_instance.stub(:parse_symbol_value_to_string)
    subject.find_symbol_type_in_collection
  end

  it 'parse_symbol_value_to_string' do
    path = 'spec/support/data/convert/entries/symbol_test/symbol_entry.json'
    entry_attributes = JSON.parse(File.read(path))
    subject.send(:parse_symbol_value_to_string, path, 3, 'stars', entry_attributes)

  end

  # it 'publish_all_entries' do
  #   vcr('import/publish_entries') do
  #     subject.publish_all_entries
  #   end
  # end

end