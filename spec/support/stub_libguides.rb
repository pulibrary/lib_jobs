# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
def stub_libguides_az_list
  body = <<-END_BODY
      [{"id":"56948275",
        "name":"University of Manchester Library, Nashriyah: Digital Iranian History, Digitized Iranian newspapers and periodicals held by the University of Manchester",
        "description":
        "The newspapers and periodicals digitized here many of which have been only partially accessible inside Iran, cover the defining moments from the following three eras...",
        "url":"https://library.princeton.edu/resource/43952",
        "site_id":"77",
        "type_id":"10",
        "owner_id":"326138",
        "az_vendor_id":"0",
        "meta":{"target":"0", "tn_url":"", "tn_height":"", "tn_width":"", "tn_alt_text":"", "more_info":"", "desc_pos":"1", "enable_proxy":"1"},
        "created":"2020-08-28 14:24:17",
        "updated":"2023-01-20 02:54:01",
        "slug_id":"2745650",
        "enable_hidden":"0",
        "az_vendor_name":null,
        "subjects":
        [{"id":"213486",
        "site_id":"77",
        "parent_id":"0",
        "name":"Near Eastern Studies",
        "ordering":"0",
        "slug_id":"0",
        "subject_id":"213486",
        "content_id":"56948275",
        "featured":"0",
        "content_id_count":"1"}],
        "friendly_url":"https://libguides.princeton.edu/resource/43952",
        "internal_note":"",
        "library_review":"",
        "alt_names":""}]
      END_BODY
  stub_request(:get, "https://lgapi-us.libapps.com/1.2/az?expand=subjects,friendly_url,az_props")
    .with(
    headers: {
      'Authorization' => 'Bearer MY_GREAT_ACCESS_TOKEN'
    }
  )
    .to_return(status: 200, body:)
end
# rubocop:enable Metrics/MethodLength

def stub_libapps_token
  body = <<-END_BODY
      {"access_token":"MY_GREAT_ACCESS_TOKEN","token_type":"bearer","refresh_token":"refreshtoken","expires_in":631138518,"scope":"/read-public","orcid":null}
  END_BODY
  stub_request(:post, 'https://lgapi-us.libapps.com/1.2/oauth/token')
    .to_return(status: 200, body:)
end
