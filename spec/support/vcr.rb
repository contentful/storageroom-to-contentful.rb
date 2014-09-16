require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.default_cassette_options = {record: :once}
  c.register_request_matcher(:credentials) do |request1, request2|
    request1.uri 'http://api.storageroomapp.com/accounts/:account_id/collections.json?auth_token=token'
    request2.uri
  end
end

def vcr(name, &block)
  VCR.use_cassette(name, &block)
end

def expect_vcr(name, &block)
  expect { VCR.use_cassette(name, &block) }
end