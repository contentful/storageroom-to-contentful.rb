require 'spec_helper'
require 'contentful_importer'

describe ContentfulImporter do

  before do
    ContentfulImporter.any_instance.stub(:credentials).and_return(YAML.load_file('spec/support/credentials_spec.yaml'))
  end

  it 'create_space' do
    vcr('import/crate_space') do
      ContentfulImporter.any_instance.stub(:gets).and_return('test')
      space = subject.create_space
      expect(space.name).to eq 'test'
    end
  end

  it 'import_content_types' do
    vcr('import/crate_space') do
      ContentfulImporter.any_instance.stub(:gets).and_return('test')
      space = subject.create_space
      expect(space.name).to eq 'test'
    end
  end
end