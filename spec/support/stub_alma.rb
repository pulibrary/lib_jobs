module AlmaStubbing
  def stub_alma_bibs(ids:, status:, fixture:, apikey:)
    ids = Array.wrap(ids)
    alma_path = Pathname.new(file_fixture_path).join("alma", fixture)
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs?apikey=#{apikey}&mms_id=#{ids}/")
      .to_return(status: status, body: alma_path, headers: { 'Content-Type' => 'application/xml' })
  end
end

RSpec.configure do |config|
  config.include AlmaStubbing
end
