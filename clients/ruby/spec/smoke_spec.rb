# frozen_string_literal: true

# Hand-written smoke test (committed, unlike spec/api/*_spec.rb and
# spec/spec_helper.rb which are generator output and gitignored). Proves the
# generated client can actually perform a real HTTP call end-to-end -- build
# a request, send it, parse the response into a typed model -- against a
# local stub server, never a live backend.

require 'webrick'
require 'json'
require 'certharbor-client'

RSpec.describe 'CaApi smoke test' do
  let(:fixture) do
    {
      subject: 'certharbor root CA',
      fingerprintSha256: 'ab:cd:ef:00',
      notBefore: '2026-01-01T00:00:00Z',
      notAfter: '2027-01-01T00:00:00Z',
      reachable: true
    }
  end

  around do |example|
    server = WEBrick::HTTPServer.new(Port: 0, Logger: WEBrick::Log.new(File::NULL),
                                      AccessLog: [])
    server.mount_proc('/api/v1/ca') do |_req, res|
      res.status = 200
      res.content_type = 'application/json'
      res.body = fixture.to_json
    end

    thread = Thread.new { server.start }
    sleep 0.05 until server.status == :Running

    @port = server.config[:Port]
    example.run
  ensure
    server&.shutdown
    thread&.join
  end

  it 'parses a real response from CaApi#get_ca into CaInfoBody' do
    config = CertharborClient::Configuration.new do |c|
      c.scheme = 'http'
      c.host = "127.0.0.1:#{@port}"
      c.base_path = ''
    end
    api = CertharborClient::CaApi.new(CertharborClient::ApiClient.new(config))

    result = api.get_ca

    expect(result).to be_a(CertharborClient::CaInfoBody)
    expect(result.subject).to eq(fixture[:subject])
    expect(result.fingerprint_sha256).to eq(fixture[:fingerprintSha256])
    expect(result.reachable).to eq(true)
  end
end
