module AlmaStubbing
  def stub_alma_bibs
    ids = Array.wrap(ids)
    alma_path = Pathname.new(file_fixture_path).join("alma")
    stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{ids}/")
      .to_return(status:, body: all_items_path, headers: { 'Content-Type' => 'application/xml' })
  end
end
