require 'nokogiri'
require 'faraday'
require 'json'
require 'bigdecimal'
def get_invoices_from_alma_file(filename)
  doc = File.open(filename) { |f| Nokogiri::XML(f) }
  doc.xpath('//xmlns:invoice_list/xmlns:invoice')
end

def currency_decimals
  {
    'BHD' => 3,
    'CVE' => 0,
    'JPY' => 0,
    'ISK' => 0,
    'KRW' => 0
  }
end

def original_currency_decimals(currency_code)
  decimals = currency_decimals[currency_code]
  decimals ||= 2
end

def get_invoice_notes(invoice)
  notes = []
  invoice.xpath('xmlns:noteList/xmlns:note').each do |note|
    content = note.at_xpath('xmlns:content').text
    notes << content
  end
  notes
end

def get_invoice_vndr_loc(invoice)
  notes = get_invoice_notes(invoice)
  notes.each do |note|
    next unless note =~ /^vendor_loc: L000[1-9]$/
    return note.gsub(/^vendor_loc: (L000[1-9])$/, '\1')
  end
  return nil
end

def get_alma_header_info(invoice)
  header_hash = {}
  header_hash[:vendor_id] = invoice.at_xpath('xmlns:vendor_FinancialSys_Code').text
  header_hash[:unique_identifier] = invoice.at_xpath('xmlns:unique_identifier').text
  header_hash[:voucher_id] = invoice.at_xpath('xmlns:invoice_ref_num').text
  invoice_id = invoice.at_xpath('xmlns:invoice_number').text
  invoice_id.gsub!(/[^0-9a-zA-Z]/, '')
  header_hash[:invoice_id] = invoice_id
  inv_date = invoice.at_xpath('xmlns:invoice_date').text
  inv_date.gsub!(/^([0-9]{2}).([0-9]{2}).([0-9]{4})$/, '\3-\1-\2')
  header_hash[:invoice_dt] = inv_date
  inv_create_date = invoice.at_xpath('xmlns:invoice_ownered_entity/xmlns:creationDate').text
  inv_create_date.gsub!(/^([0-9]{4})([0-9]{2})([0-9]{2})$/, '\1-\2-\3')
  header_hash[:invoice_create_date] = inv_create_date
  headher_hash[:total_invoice_amount] = invoice.at_xpath('xmlns:invoice_amount/xmlns:sum').text
  header_hash[:currency] = invoice.at_xpath('xmlns:invoice_amount/xmlns:currency').text
  vndr_loc = invoice.at_xpath('xmlns:vendor_additional_code')
  vndr_loc = vndr_loc.text if vndr_loc
  header_hash[:vndr_loc] = vndr_loc
  header_hash
end

def format_usd_amount(amount_string)
  case amount_string
    when /^[0-9]+\.[0-9]{2}$/
      amount_string
    when /^[0-9]+\.[0-9]$/
      amount_string + '0'
    when /^[0-9]+$/
    amount_string + '.00'
  end
end

def get_currency_codes_for_invoice(line_items)
  currency_codes = []
  line_items.each do |line_item|
    currency_codes += get_currency_codes_from_funds(line_item[:fund_list])
  end
  currency_codes.uniq
end

def get_invoice_original_amount_total(line_items:, currency_code:)
  decimals = original_currency_decimals(currency_code)
  total = BigDecimal('0')
  line_items.each do |line_item|
    total += line_item[:total_local_amount]
  end
  if decimals == 0
    total = total.to_s('F')
    parts = total.split('.')
    parts[0] # integer value
  else
    total = total.truncate(decimals)
    total = total.to_s('F')
    parts = total.split('.')
    num = parts[0]
    dec_places = parts[1]
    while dec_places.size < decimals
      dec_places << '0'
    end
    num + '.' + dec_places
  end
end

def get_invoice_local_amount_total(line_items)
  total = BigDecimal('0')
  line_items.each do |line_item|
    total += line_item[:total_local_amount]
  end
  total = total.to_s('F')
  parts = total.split('.')
  num = parts[0]
  dec_places = parts[1]
  while dec_places < 2
    dec_places << '0'
  end
  num + '.' + dec_places
end

def get_fund_list(line_item)
  fund_list = []
  line_item.xpath('xmlns:fund_info_list/xmlns:fund_info').each do |fund|
    hash = {}
    hash[:original_amount] = fund.at_xpath('xmlns:amount/xmlns:sum').text
    hash[:original_currency] = fund.at_xpath('xmlns:amount/xmlns:currency').text
    usd_amount = fund.at_xpath('xmlns:local_amount/xmlns:sum').text
    hash[:usd_amount] = format_usd_amount(usd_amount)
    chartstring = fund.at_xpath('xmlns:external_id')
    if chartstring
      chartstring = chartstring.text
      string_parts = chartstring.split('|')
      hash[:prime_dept] = string_parts[0]
      hash[:prime_fund] = string_parts[1]
      hash[:prime_program] = string_parts[2]
    end
    hash[:chartstring] = chartstring
    hash[:prime_fund] ||= nil
    hash[:prime_dept] ||= nil
    hash[:prime_program] ||= nil
    hash[:ledger] = fund.at_xpath('xmlns:ledger_code').text
    hash[:fiscal_period] = fund.at_xpath('xmlns:fiscal_period').text
    fund_list << hash
  end
  fund_list
end

def get_total_local_amount_from_funds(fund_list)
  total = BigDecimal('0')
  fund_list.each do |fund|
    amount = BigDecimal(fund[:usd_amount])
    total += amount
  end
  total
end

def get_total_original_amount_from_funds(fund_list)
  total = BigDecimal('0')
  fund_list.each do |fund|
    amount = BigDecimal(fund[:original_amount])
    total += amount
  end
  total
end

def get_currency_codes_from_funds(fund_list)
  codes = []
  fund_list.each do |fund|
    codes << fund[:original_currency]
  end
  codes
end

def get_alma_po_info(line_item)
  hash = {}
  raw_title = line_item.at_xpath('xmlns:po_line_info/xmlns:po_line_title')
  title = raw_title ? raw_title.text.unicode_normalize(:nfd) : 'adjustment'
  title.encode!('ISO-8859-1', invalid: :replace, undef: :replace, replace: '')
  hash[:title] = title[0..253]
  po_line_number = line_item.at_xpath('xmlns:po_line_info/xmlns:po_line_number')
  hash[:po_line_number] = po_line_number ? po_line_number.text : ''
  bib_id = line_item.at_xpath('xmlns:po_line_info/xmlns:mms_record_id')
  hash[:bib_id] = bib_id ? bib_id.text : ''
  vendor_ref_num = line_item.at_xpath('xmlns:po_line_info/xmlns:vendor_reference_number')
  hash[:vendor_ref_num] = vendor_ref_num ? vendor_ref_num.text : ''
  hash
end

### Reporting code is used for the entire invoice line instead of each payment
def parse_alma_line_item(line_item)
  line_item_hash = {}
  line_item_hash[:inv_line_number] = line_item.at_xpath('xmlns:line_number').text
  line_item_hash[:reporting_code] = line_item.at_xpath('xmlns:reporting_code').text
  line_item_hash[:fund_list] = get_fund_list(line_item)
  line_item_hash[:currencies] = get_currency_codes_from_funds(line_item_hash[:fund_list])
  line_item_hash[:total_local_amount] = get_total_local_amount_from_funds(line_item_hash[:fund_list])
  line_item_hash[:total_original_amount] = get_total_original_amount_from_funds(line_item_hash[:fund_list])
  line_item_hash[:inv_line_note] = line_item.at_xpath('xmlns:note').text
  po_info = get_alma_po_info(line_item)
  line_item_hash[:title] = po_info[:title]
  line_item_hash[:po_line_number] = po_info[:po_line_number]
  line_item_hash[:vendor_ref_num] = po_info[:vendor_ref_num]
  line_item_hash[:bib_id] = po_info[:bib_id]
  line_item_hash
end

### Return a hash with all line items in one element, and a Boolean
###   that is true if there are any line items with errors;
###   amount is in the original currency, so it needs to be converted later
def get_alma_line_items(invoice)
  line_items = []
  invoice.xpath('xmlns:invoice_line_list/xmlns:invoice_line').each do |line_item|
    line_info = parse_alma_line_item(line_item)
    line_items << line_info
  end
  line_items
end

def api_conn(url)
  Faraday.new(url: url) do |faraday|
    faraday.request   :url_encoded
    faraday.response  :logger
    faraday.adapter   Faraday.default_adapter
  end
end

def get_vendor_codes(conn:, api_key:)
  offset = 0
  vendor_codes = []
  batch1 = conn.get do |req|
    req.url "almaws/v1/acq/vendors"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.params['apikey'] = api_key
    req.params['status'] = 'active'
    req.params['limit'] = '100'
    req.params['offset'] = offset.to_s
  end
  batch1.body.force_encoding('utf-8')
  body = JSON.parse(batch1.body)
  return vendors if body['vendor'].nil?
  total_recs = body['total_record_count'].to_i
  body['vendor'].each do |vendor|
    vendor_codes << vendor['code']
  end
  offset += 100
  while offset < total_recs
    response = conn.get do |req|
      req.url "almaws/v1/acq/vendors"
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
      req.params['apikey'] = api_key
      req.params['status'] = 'active'
      req.params['limit'] = '100'
      req.params['offset'] = offset.to_s
    end
    response.body.force_encoding('utf-8')
    body = JSON.parse(response.body)
    body['vendor'].each do |vendor|
      vendor_codes << vendor['code']
    end
    offset += 100
  end
  vendor_codes.uniq
end

def get_vendor(conn:, api_key:, vendor_code:)
  response = conn.get do |req|
    req.url "almaws/v1/acq/vendors/#{vendor_code}"
    req.headers['Content-Type'] = 'application/xml'
    req.headers['Accept'] = 'application/xml'
    req.params['apikey'] = api_key
  end
  return nil if response.status != 200

  response.body.force_encoding('utf-8')
  Nokogiri::XML(response.body)
end

def get_vendors(conn:, api_key:)
  vendor_codes = get_vendor_codes(conn: conn, api_key: api_key)
  vendors = {}
  vendor_codes.each do |vendor_code|
    response = conn.get do |req|
      req.url "almaws/v1/acq/vendors/#{vendor_code}"
      req.headers['Content-Type'] = 'application/xml'
      req.headers['Accept'] = 'application/xml'
      req.params['apikey'] = api_key
    end
    next if response.status != 200
    response.body.force_encoding('utf-8')
    doc = Nokogiri::XML(response.body)
    vendors[vendor_code] = doc
  end
  vendors
end

def get_fund_by_id(fund_id:, conn:, api_key:)
  response = conn.get do |req|
    req.url "almaws/v1/acq/funds/#{fund_id}"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.params['apikey'] = api_key
  end
  return nil if response.status != 200
  response.body.force_encoding('utf-8')
  JSON.parse(response.body)
end

def alma_fund_mapping
  {
    'A0101' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'A0301' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'A0305' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'A0350' => { descr: 'Jewish Studies Endowment', fund: 'E2772-no program', external_id: '41100|E2772' },
    'A0401' => { descr: 'New & Exp. Fields', fund: 'AN500', external_id: '41100|E9994|AN500' },
    'A0501' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B0101' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B0201' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B0301' => { descr: 'Firestone Reserve', fund: 'AN501', external_id: '41100|E9994|AN501' },
    'B0401' => { descr: 'Newspapers', fund: 'AN502', external_id: '41100|E9994|AN502' },
    'B0501' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B0601' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B0701' => { descr: 'Library General Acquisitions', fund: 'E9994-Lib Science-no program', external_id: '41101|E9994' },
    'B0801' => { descr: 'General Periodicals', fund: 'AN503', external_id: '41100|E9994|AN503' },
    'B0901' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B1001' => { descr: 'General Reference', fund: 'AN505', external_id: '41100|E9994|AN505' },
    'B1101' => { descr: 'Library General Acquisitions', fund: 'E9994-no program', external_id: '41100|E9994' },
    'B1202' => { descr: 'Contemporary Literature', fund: 'AN504', external_id: '41104|E9994|AN504' },
    'B1302' => { descr: 'Library General Acquisitions', fund: 'E9994-Archives-no program', external_id: '41169|E9994' },
    'B1350' => { descr: 'Dulles, JA and JF Library', fund: 'E0482-Archives-no program', external_id: '41169|E0482' },
    'B1401' => { descr: 'Library General Acquisitions', fund: 'E9994-Preservation Ref-no program', external_id: '41175|E9994' },
    'B1501' => { descr: 'Library General Acquisitions', fund: 'E9994-Fac Publications-no program', external_id: '41176|E9994' },
    'C0101' => { descr: 'Library General Acquisitions', fund: 'E9994-Arch-no program', external_id: '41102|E9994' },
    'C0102' => { descr: 'Library General Acquisitions', fund: 'E9994-Arch-no program', external_id: '41102|E9994' },
    'C0201' => { descr: 'Library General Acquisitions', fund: 'E9994-Classics-no program', external_id: '41103|E9994' },
    'C0202' => { descr: 'Library General Acquisitions', fund: 'E9994-Classics-no program', external_id: '41103|E9994' },
    'C0281' => { descr: 'Katz, Joshua', fund: 'FA482', external_id: '41103|E3478|FA482' },
    'C0284' => { descr: 'Winans Memorial', fund: 'AN565', external_id: '41103|E9994|AN565' },
    'C0285' => { descr: 'Katster, Robert A', fund: 'FA523', external_id: '41103|E3478|FA523' },
    'C0402' => { descr: 'Library General Acquisitions', fund: 'E9994-Eng & Am Lit-no program', external_id: '41104|E9994' },
    'C0403' => { descr: 'English Literature', fund: 'AN506', external_id: '41104|E9994|AN506' },
    'C0404' => { descr: 'American Lit', fund: 'AN507', external_id: '41104|E9994|AN507' },
    'C0405' => { descr: 'Medieval English', fund: 'AN508', external_id: '41104|E9994|AN508' },
    'C0406' => { descr: 'Modern Lang English', fund: 'AN509', external_id: '41104|E9994|AN509' },
    'C0407' => { descr: 'Poetry', fund: 'AN510', external_id: '41104|E9994|AN510' },
    'C0408' => { descr: 'American Fiction', fund: 'AN511', external_id: '41104|E9994|AN511' },
    'C0409' => { descr: 'Celtic Poetry', fund: 'AN512', external_id: '41104|E9994|AN512' },
    'C0483' => { descr: 'Danson, Lawrence', fund: 'FB330', external_id: '41104|E3478|FB330' },
    'C0484' => { descr: 'Sitney, P Adams', fund: 'FA084', external_id: '41104|E3478|FA084' },
    'C0485' => { descr: 'Nord, Deborah E', fund: 'FA302', external_id: '41104|E3478|FA302' },
    'C0486' => { descr: 'Fuss, Diana J', fund: 'FA271', external_id: '41104|E3478|FA271' },
    'C0487' => { descr: 'Gikandi, Simon E', fund: 'FA731', external_id: '41104|E3478|FA731' },
    'C0501' => { descr: 'Library General Acquisitions', fund: 'E9994-French-no program', external_id: '41117|E9994' },
    'C0502' => { descr: 'Library General Acquisitions', fund: 'E9994-French-no program', external_id: '41117|E9994' },
    'C0503' => { descr: 'Le Brun Collection', fund: 'AN513', external_id: '41117|E9994|AN513' },
    'C0601' => { descr: 'Library General Acquisitions', fund: 'E9994-German-no program', external_id: '41116|E9994' },
    'C0602' => { descr: 'Library General Acquisitions', fund: 'E9994-German-no program', external_id: '41116|E9994' },
    'C0702' => { descr: 'Library General Acquisitions', fund: 'E9994-History-no program', external_id: '41105|E9994' },
    'C0703' => { descr: 'American History', fund: 'AN514', external_id: '41105|E9994|AN514' },
    'C0704' => { descr: 'Southern U.S. History', fund: 'AN515', external_id: '41105|E9994|AN515' },
    'C0705' => { descr: 'Naval History', fund: 'AN516', external_id: '41105|E9994|AN516' },
    'C0706' => { descr: 'American West History', fund: 'AN517', external_id: '41105|E9994|AN517' },
    'C0707' => { descr: 'New England & NY History', fund: 'AN518', external_id: '41105|E9994|AN518' },
    'C0708' => { descr: 'American Civil War History', fund: 'AN519', external_id: '41105|E9994|AN519' },
    'C0709' => { descr: 'American Colonial Hist.', fund: 'AN520', external_id: '41105|E9994|AN520' },
    'C0710' => { descr: 'World History', fund: 'AN521', external_id: '41105|E9994|AN521' },
    'C0712' => { descr: 'Northern New York Hist.', fund: 'AN522', external_id: '41105|E9994|AN522' },
    'C0713' => { descr: 'Constitutional History', fund: 'AN523', external_id: '41105|E9994|AN523' },
    'C0750' => { descr: 'Department Discretionary Gifts', fund: 'B0001-His-no program', external_id: '41105|B0001' },
    'C0783' => { descr: 'Grafton, Anthony T', fund: 'FA103', external_id: '41105|E3478|FA103' },
    'C0802' => { descr: 'Library General Acquisitions', fund: 'E9994-History of Sci-no program', external_id: '41106|E9994' },
    'C0901' => { descr: 'Library General Acquisitions', fund: 'E9994-Italian-no program', external_id: '41118|E9994' },
    'C0902' => { descr: 'Library General Acquisitions', fund: 'E9994-Italian-no program', external_id: '41118|E9994' },
    'C1001' => { descr: 'Library General Acquisitions', fund: 'E9994-Linguistics-no program', external_id: '41107|E9994' },
    'C1051' => { descr: 'Library Acquisitions Fund', fund: 'A0007-Linguistics-no program', external_id: '41107|A0007' },
    'C1080' => { descr: 'Rosen, Gideon A', fund: 'FA015', external_id: '41107|E3478|FA015' },
    'C1101' => { descr: 'Library General Acquisitions', fund: 'E9994-Music & Perf Arts-no program', external_id: '41108|E9994' },
    'C1103' => { descr: 'Music', fund: 'AN524', external_id: '41108|E9994|AN524' },
    'C1105' => { descr: 'Theater', fund: 'AN525', external_id: '41108|E9994|AN525' },
    'C1106' => { descr: "Imbrie '84 Music", fund: 'AN526', external_id: '41108|E9994|AN526' },
    'C1107' => { descr: 'Recorded Music', fund: 'AN527', external_id: '41108|E9994|AN527' },
    'C1150' => { descr: 'Presser Foundation', fund: 'E0353-no program', external_id: '41108|E0353' },
    'C1180' => { descr: 'Sandberg, Robert N', fund: 'FA444', external_id: '41108|E3478|FA444' },
    'C1201' => { descr: 'Library General Acquisitions', fund: 'E9994-Numismatics-no program', external_id: '41109|E9994' },
    'C1250' => { descr: 'Townsend-Vermeule', fund: 'E3053-no program', external_id: '41109|E3053' },
    'C1301' => { descr: 'Library General Acquisitions', fund: 'E9994-Philosophy-no program', external_id: '41110|E9994' },
    'C1302' => { descr: 'Library General Acquisitions', fund: 'E9994-Philosophy-no program', external_id: '41110|E9994' },
    'C1380' => { descr: 'Nehamas, Alexander', fund: 'FA163', external_id: '41110|E3478|FA163' },
    'C1381' => { descr: 'Morison, Benjamin C', fund: 'FA717', external_id: '41110|E3478|FA717' },
    'C1401' => { descr: 'Library General Acquisitions', fund: 'E9994-Religion-no program', external_id: '41111|E9994' },
    'C1402' => { descr: 'Library General Acquisitions', fund: 'E9994-Religion-no program', external_id: '41111|E9994' },
    'C1502' => { descr: 'Library Special Acquisitions', fund: 'E9995-Art & Arch-no program', external_id: '41112|E9995' },
    'C1503' => { descr: 'Christian & Medieval', fund: 'AN528', external_id: '41112|E9995|AN528' },
    'C1504' => { descr: 'Gardening', fund: 'AN529', external_id: '41112|E9995|AN529' },
    'C1505' => { descr: 'Photography', fund: 'AN530', external_id: '41112|E9995|AN530' },
    'C1551' => { descr: 'Laura P Hall Mem Coll Art & Arch', fund: 'E0289-Art & Arch-no program', external_id: '41112|E0289' },
    'C1602' => { descr: 'Chinese Art', fund: 'AN531', external_id: '41112|E9995|AN531' },
    'C1702' => { descr: 'Japanese Art', fund: 'AN532', external_id: '41112|E9995|AN532' },
    'C1801' => { descr: 'Library General Acquisitions', fund: 'E9994-Comp Lit-no program', external_id: '41113|E9994' },
    'C1802' => { descr: 'Library General Acquisitions', fund: 'E9994-Comp Lit-no program', external_id: '41113|E9994' },
    'C1901' => { descr: 'Library General Acquisitions', fund: 'E9994-Journalism-no program', external_id: '41177|E9994' },
    'D0101' => { descr: 'Library General Acquisitions', fund: 'E9994-African Amer Studies-no program', external_id: '41114|E9994' },
    'D0180' => { descr: 'Smith, Valerie A.', fund: 'OA051', external_id: '41114|E3478|OA051' },
    'D0181' => { descr: 'Benjamin, Ruha', fund: 'FB474', external_id: '41114|E3478|FB474' },
    'D0201' => { descr: 'Library General Acquisitions', fund: 'E9994-Anthropology-no program', external_id: '41115|E9994' },
    'D0281' => { descr: 'Greenhouse, Carol J', fund: 'FA532', external_id: '41115|E3478|FA532' },
    'D0301' => { descr: 'Library General Acquisitions', fund: 'E9994-Documents-no program', external_id: '41120|E9994' },
    'D0401' => { descr: 'Library General Acquisitions', fund: 'E9994-Economics-no program', external_id: '41121|E9994' },
    'D0402' => { descr: 'Library General Acquisitions', fund: 'E9994-Economics-no program', external_id: '41121|E9994' },
    'D0450' => { descr: 'Library General Acquisitions', fund: 'A0007-Econ-no program', external_id: '41121|A0007' },
    'D0501' => { descr: 'Library General Acquisitions', fund: 'E9994-Education-no program', external_id: '41122|E9994' },
    'D0503' => { descr: 'American Education', fund: 'AN533', external_id: '41122|E9994|AN533' },
    'D0601' => { descr: 'Library General Acquisitions', fund: 'E9994-Law-no program', external_id: '41123|E9994' },
    'D0602' => { descr: 'Library General Acquisitions', fund: 'E9994-Law-no program', external_id: '41123|E9994' },
    'D0603' => { descr: 'Jurisprudence', fund: 'AN534', external_id: '41123|E9994|AN534' },
    'D0680' => { descr: 'Hartok, Hendrik A.', fund: 'FA368', external_id: '41123|E3478|FA368' },
    'D0701' => { descr: 'Library General Acquisitions', fund: 'E9994-Politics-no program', external_id: '41124|E9994' },
    'D0702' => { descr: 'Library General Acquisitions', fund: 'E9994-Politics-no program', external_id: '41124|E9994' },
    'D0703' => { descr: 'Politics International Affairs', fund: 'AN535', external_id: '41124|E9994|AN535' },
    'D0780' => { descr: 'Viroli, Maurizio', fund: 'FA146', external_id: '41124|E3478|FA146' },
    'D0781' => { descr: 'George, Robert P', fund: 'FA186', external_id: '41124|E3478|FA186' },
    'D0801' => { descr: 'Library General Acquisitions', fund: 'E9994-Pop Research-no program', external_id: '41125|E9994' },
    'D0802' => { descr: 'Library General Acquisitions', fund: 'E9994-Pop Research-no program', external_id: '41125|E9994' },
    'D0901' => { descr: 'Library General Acquisitions', fund: 'E9994-Soc Science-no program', external_id: '41126|E9994' },
    'D1001' => { descr: 'Library General Acquisitions', fund: 'E9994-Gen Social Sci.-no program', external_id: '41127|E9994' },
    'D1101' => { descr: 'Library General Acquisitions', fund: 'E9994-Sociology-no program', external_id: '41128|E9994' },
    'D1102' => { descr: 'Library General Acquisitions', fund: 'E9994-Sociology-no program', external_id: '41128|E9994' },
    'D1180' => { descr: 'Duneier, Mitchell', fund: 'FA658', external_id: '41128|E3478|FA658' },
    'D1181' => { descr: 'Duneier, Mitchell', fund: 'FA658', external_id: '41128|E3478|FA658' },
    'D1182' => { descr: 'Lisanti, Mariangela', fund: 'FB345', external_id: '41128|E3478|FB345' },
    'D1201' => { descr: 'Library General Acquisitions', fund: 'E9994-Sports & Games-no program', external_id: '41129|E9994' },
    'D1301' => { descr: 'Library General Acquisitions', fund: 'E9994-UN-no program', external_id: '41130|E9994' },
    'D1302' => { descr: 'Library General Acquisitions', fund: 'E9994-UN-no program', external_id: '41130|E9994' },
    'D1401' => { descr: 'Library General Acquisitions', fund: 'E9994-Women Gndr Sexuality-no program', external_id: '41131|E9994' },
    'D1402' => { descr: 'Library General Acquisitions', fund: 'E9994-Women Gndr Sexuality-no program', external_id: '41131|E9994' },
    'D1480' => { descr: 'Wolf, Stacy E', fund: 'FA949', external_id: '41131|E3478|FA949' },
    'D1501' => { descr: 'Library General Acquisitions', fund: 'E9994-Sch Public & Intl Affairs-no program', external_id: '41132|E9994' },
    'D1502' => { descr: 'Library General Acquisitions', fund: 'E9994-Sch Public & Intl Affairs-no program', external_id: '41132|E9994' },
    'D1503' => { descr: 'International Affairs', fund: 'AN536', external_id: '41132|E9994|AN536' },
    'D1504' => { descr: 'Public Relations', fund: 'AN537', external_id: '41132|E9994|AN537' },
    'D1505' => { descr: 'Multinational Corporation', fund: 'AN538', external_id: '41132|E9994|AN538' },
    'D1601' => { descr: 'Library General Acquisitions', fund: 'E9994-Marketing-no program', external_id: '41133|E9994' },
    'D1702' => { descr: 'Library Special Acquisitions', fund: 'E9995-Ind Relations-no program', external_id: '41134|E9995' },
    'D1850' => { descr: 'Bioethics', fund: 'AN559', external_id: '41123|E9994|AN559' },
    'D1901' => { descr: 'Library General Acquisitions', fund: 'E9994-Finance-no program', external_id: '41174|E9994' },
    'E0101' => { descr: 'Library General Acquisitions', fund: 'E9994-Astrophysics-no program', external_id: '41135|E9994' },
    'E0180' => { descr: 'Spergel, David N', fund: 'FA127', external_id: '41135|E3478|FA127' },
    'E0201' => { descr: 'Library General Acquisitions', fund: 'E9994-Bio Sciences-no program', external_id: '41136|E9994' },
    'E0202' => { descr: 'Library General Acquisitions', fund: 'E9994-Bio Sciences-no program', external_id: '41136|E9994' },
    'E0203' => { descr: 'Molecular Biology', fund: 'AN539', external_id: '41136|E9994|AN539' },
    'E0204' => { descr: 'Medicine', fund: 'AN540', external_id: '41136|E9994|AN540' },
    'E0281' => { descr: 'Hughson, Frederick M', fund: 'FA534', external_id: '41136|E3478|FA534' },
    'E0282' => { descr: 'Wingreen, Ned', fund: 'FA730', external_id: '41136|E3478|FA730' },
    'E0301' => { descr: 'Library General Acquisitions', fund: 'E9994-Chemistry-no program', external_id: '41137|E9994' },
    'E0302' => { descr: 'Library General Acquisitions', fund: 'E9994-Chemistry-no program', external_id: '41137|E9994' },
    'E0303' => { descr: 'High Polymer Chemistry', fund: 'AN541', external_id: '41137|E9994|AN541' },
    'E0501' => { descr: 'Library General Acquisitions', fund: 'E9994-Engineering-no program', external_id: '41138|E9994' },
    'E0502' => { descr: 'Library General Acquisitions', fund: 'E9994-Engineering-no program', external_id: '41138|E9994' },
    'E0503' => { descr: 'Aeronautics', fund: 'AN542', external_id: '41138|E9994|AN542' },
    'E0504' => { descr: 'Chemical Engineering', fund: 'AN543', external_id: '41138|E9994|AN543' },
    'E0505' => { descr: 'Electrical Engineering', fund: 'AN544', external_id: '41138|E9994|AN544' },
    'E0506' => { descr: 'Aviation & Aerospace Engrng', fund: 'AN545', external_id: '41138|E9994|AN545' },
    'E0507' => { descr: 'Civil Engineering', fund: 'AN546', external_id: '41138|E9994|AN546' },
    'E0581' => { descr: 'Sturm, James C', fund: 'FA160', external_id: '41138|E3478|FA160' },
    'E0582' => { descr: 'Sundaresan, Sankaran', fund: 'FA229', external_id: '41138|E3478|FA229' },
    'E0583' => { descr: 'Kulkarni, Sanjeev R', fund: 'FA339', external_id: '41138|E3478|FA339' },
    'E0584' => { descr: 'Smits, Alexander, J', fund: 'FA143', external_id: '41138|E3478|FA143' },
    'E0585' => { descr: 'Debenedetti, Pablo G', fund: 'FA079', external_id: '41138|E3478|FA079' },
    'E0586' => { descr: 'Malik, Sharad', fund: 'FA332', external_id: '41138|E3478|FA332' },
    'E0588' => { descr: 'Garlock, Maria E', fund: 'FA657', external_id: '41138|E3478|FA657' },
    'E0589' => { descr: 'Houck, Andrew A', fund: 'FA059', external_id: '41138|E3478|FA059' },
    'E0590' => { descr: 'Gmachl, Claire F', fund: 'FA713', external_id: '41138|E3478|FA713' },
    'E0591' => { descr: 'Prucnal, Paul R', fund: 'FA082', external_id: '41138|E3478|FA082' },
    'E0592' => { descr: 'Kernighan, Brian W', fund: 'FA393', external_id: '41138|E3478|FA393' },
    'E0593' => { descr: 'Nelson, Celeste M', fund: 'FA872', external_id: '41138|E3478|FA872' },
    'E0594' => { descr: 'Stone, Howard A', fund: 'FA948', external_id: '41138|E3478|FA948' },
    'E0601' => { descr: 'Library General Acquisitions', fund: 'E9994-Gen Science-no program', external_id: '41139|E9994' },
    'E0701' => { descr: 'Library General Acquisitions', fund: 'E9994-Energy & Environment-no program', external_id: '41140|E9994' },
    'E0702' => { descr: 'Library General Acquisitions', fund: 'E9994-Energy & Environment-no program', external_id: '41140|E9994' },
    'E0801' => { descr: 'Library General Acquisitions', fund: 'E9994-Geosciences-no program', external_id: '41141|E9994' },
    'E0802' => { descr: 'Library General Acquisitions', fund: 'E9994-Geosciences-no program', external_id: '41141|E9994' },
    'E0901' => { descr: 'Library General Acquisitions', fund: 'E9994-GIS & Contemp Maps-no program', external_id: '41142|E9994' },
    'E1001' => { descr: 'Library General Acquisitions', fund: 'E9994-Mathematics-no program', external_id: '41143|E9994' },
    'E1002' => { descr: 'Library General Acquisitions', fund: 'E9994-Mathematics-no program', external_id: '41143|E9994' },
    'E1003' => { descr: 'Statistics', fund: 'AN547', external_id: '41143|E9994|AN547' },
    'E1101' => { descr: 'Library General Acquisitions', fund: 'E9994-Physics-no program', external_id: '41144|E9994' },
    'E1102' => { descr: 'Library General Acquisitions', fund: 'E9994-Physics-no program', external_id: '41144|E9994' },
    'E1180' => { descr: 'Bailek, William', fund: 'FA348', external_id: '41144|E3478|FA348' },
    'E1201' => { descr: 'Library General Acquisitions', fund: 'E9994-Behavioral Sciences-no program', external_id: '41145|E9994' },
    'E1202' => { descr: 'Library General Acquisitions', fund: 'E9994-Behavioral Sciences-no program', external_id: '41145|E9994' },
    'E1301' => { descr: 'Library General Acquisitions', fund: 'E9994-Plasma Physics-no program', external_id: '41146|E9994' },
    'E1403' => { descr: 'Zeiss Wildlife', fund: 'AN567', external_id: '41139|E9995|AN567' },
    'F0101' => { descr: 'Library General Acquisitions', fund: 'E9994-African Studies-no program', external_id: '41147|E9994' },
    'F0201' => { descr: 'Library General Acquisitions', fund: 'E9994-Arabic-no program', external_id: '41148|E9994' },
    'F0202' => { descr: 'Library General Acquisitions', fund: 'E9994-Arabic-no program', external_id: '41148|E9994' },
    'F0301' => { descr: 'Library General Acquisitions', fund: 'E9994-Asian American-no program', external_id: '41149|E9994' },
    'F0401' => { descr: 'Library General Acquisitions', fund: 'E9994-Chinese-no program', external_id: '41150|E9994' },
    'F0403' => { descr: 'Library General Acquisitions', fund: 'E9994-Chinese-no program', external_id: '41150|E9994' },
    'F0450' => { descr: 'Asian Studies (JDR III)', fund: 'E0329-Chinese-no program', external_id: '41150|E0329' },
    'F0501' => { descr: 'Library General Acquisitions', fund: 'E9994-East Asian-no program', external_id: '41151|E9994' },
    'F0502' => { descr: 'Library General Acquisitions', fund: 'E9994-East Asian-no program', external_id: '41151|E9994' },
    'F0580' => { descr: 'Leheny, David R', fund: 'FA893', external_id: '41151|E3478|FA893' },
    'F0602' => { descr: 'Library General Acquisitions', fund: 'E9994-Near East-no program', external_id: '41152|E9994' },
    'F0603' => { descr: 'Library General Acquisitions', fund: 'E9994-Near East-no program', external_id: '41152|E9994' },
    'F0680' => { descr: 'Cook, Michael A', fund: 'FA147', external_id: '41152|E3478|FA147' },
    'F0701' => { descr: 'Library General Acquisitions', fund: 'E9994-Hebrew-no program', external_id: '41153|E9994' },
    'F0801' => { descr: 'Library General Acquisitions', fund: 'E9994-Hellenic Studies-no program', external_id: '41154|E9994' },
    'F0850' => { descr: 'Stanley J Seeger', fund: 'E2836-Hellenic Studies-no program', external_id: '41154|E2836' },
    'F0901' => { descr: 'Library General Acquisitions', fund: 'E9994-Korean-no program', external_id: '41155|E9994' },
    'F0952' => { descr: 'Korean Foundation', fund: 'AN566', external_id: '41155|A0007|AN566' },
    'F1001' => { descr: 'Library General Acquisitions', fund: 'E9994-Japanese-no program', external_id: '41156|E9994' },
    'F1002' => { descr: 'Library General Acquisitions', fund: 'E9994-Japanese-no program', external_id: '41156|E9994' },
    'F1050' => { descr: 'Government of Japan', fund: 'E0388-Japanese-no program', external_id: '41156|E0388' },
    'F1101' => { descr: 'Library General Acquisitions', fund: 'E9994-Latin American-no program', external_id: '41157|E9994' },
    'F1102' => { descr: 'Library General Acquisitions', fund: 'E9994-Latin American-no program', external_id: '41157|E9994' },
    'F1103' => { descr: 'Library General Acquisitions', fund: 'E9994-Spanish-no program', external_id: '41119|E9994' },
    'F1104' => { descr: 'Latin American History', fund: 'AN548', external_id: '41157|E9994|AN548' },
    'F1150' => { descr: 'Lassen H D-L Amer', fund: 'E0360-no program', external_id: '41157|E0360' },
    'F1201' => { descr: 'Library General Acquisitions', fund: 'E9994-Persian-no program', external_id: '41158|E9994' },
    'F1202' => { descr: 'Library General Acquisitions', fund: 'E9994-Persian-no program', external_id: '41158|E9994' },
    'F1250' => { descr: 'Pourdavoud E Prof Persian St', fund: 'E3466-Persian-no program', external_id: '41158|E3466' },
    'F1251' => { descr: 'Pahlavi Endmt Iranian', fund: 'E0373-Persian-no program', external_id: '41158|E0373' },
    'F1301' => { descr: 'Library General Acquisitions', fund: 'E9994-Slavic-no program', external_id: '41159|E9994' },
    'F1303' => { descr: 'Slavic History', fund: 'AN563', external_id: '41159|E9994|AN563' },
    'F1401' => { descr: 'Library General Acquisitions', fund: 'E9994-Turkish-no program', external_id: '41160|E9994' },
    'F1402' => { descr: 'Library General Acquisitions', fund: 'E9994-Turkish-no program', external_id: '41160|E9994' },
    'F1403' => { descr: 'Ottoman Turkish History', fund: 'AN549', external_id: '41160|E9994|AN549' },
    'F1501' => { descr: 'Library General Acquisitions', fund: 'E9994-South Asian Studies-no program', external_id: '41161|E9994' },
    'F1601' => { descr: 'Library General Acquisitions', fund: 'E9994-Iberian Studies-no program', external_id: '41162|E9994' },
    'F1702' => { descr: 'Library General Acquisitions', fund: 'E9994-Canadian Studies-no program', external_id: '41163|E9994' },
    'G0101' => { descr: 'Library General Acquisitions', fund: 'E9994-Anglo American-no program', external_id: '41164|E9994' },
    'G0201' => { descr: 'Approval Materials', fund: 'AN556', external_id: '41116|E9994|AN556' },
    'G0202' => { descr: 'Library General Acquisitions', fund: 'E9994-German-no program', external_id: '41116|E9994' },
    'G0301' => { descr: 'Approval Materials', fund: 'AN556-French', external_id: '41117|E9994|AN556' },
    'G0401' => { descr: 'Approval Materials', fund: 'AN556-Italian', external_id: '41118|E9994|AN556' },
    'G0501' => { descr: 'Approval Materials', fund: 'AN556-Irish', external_id: '41173|E9994|AN556' },
    'G0601' => { descr: 'Library General Acquisitions', fund: 'E9994-Anglo American-no program', external_id: '41164|E9994' },
    'H0102' => { descr: 'Library Special Acquisitions', fund: 'E9995-Graphic Arts-no program', external_id: '41165|E9995' },
    'H0103' => { descr: 'Design', fund: 'AN550', external_id: '41165|E9995|AN550' },
    'H0150' => { descr: 'Elmer Adler Graphic Arts', fund: 'E0496-Graphic Arts-no program', external_id: '41165|E0496' },
    'H0202' => { descr: 'Library Special Acquisitions', fund: 'E9995-Historical Maps-no program', external_id: '41166|E9995' },
    'H0302' => { descr: 'Library Special Acquisitions', fund: 'E9995-Manuscripts-no program', external_id: '41167|E9995' },
    'H0303' => { descr: 'Sanxay', fund: 'AN551', external_id: '41167|E9995|AN551' },
    'H0304' => { descr: "Baillergen '52", fund: 'AN552', external_id: '41167|E9995|AN552' },
    'H0350' => { descr: 'Department Discretionary Gifts', fund: 'B0001-Manuscripts-no program', external_id: '41167|B0001' },
    'H0402' => { descr: 'Library Special Acquisitions', fund: 'E9995-Rare Books-no program', external_id: '41168|E9995' },
    'H0404' => { descr: 'Angling German', fund: 'AN553', external_id: '41168|E9995|AN553' },
    'H0405' => { descr: 'Architecture', fund: 'AN562-Spec Coll', external_id: '41168|E9995|AN562' },
    'H0406' => { descr: 'English Lit', fund: 'AN506-Sp Coll', external_id: '41168|E9995|AN506' },
    'H0407' => { descr: 'American Illustration', fund: 'AN554-Spec Coll', external_id: '41168|E9995|AN554' },
    'H0408' => { descr: 'Milton & Old English', fund: 'AN555-Spec Coll', external_id: '41168|E9995|AN555' },
    'H0409' => { descr: 'American Lit', fund: 'AN507-Spec Coll', external_id: '41168|E9995|AN507' },
    'H0410' => { descr: 'Hellenic Studies', fund: 'AN560-Spec Coll', external_id: '41168|E9995|AN560' },
    'H0502' => { descr: 'Library Special Acquisitions', fund: 'E9995-Western Americana-no program', external_id: '41170|E9995' },
    'H0651' => { descr: "Cotsen Children's Library", fund: 'E3577-Cotsen-no program', external_id: '41171|E3577' },
    'H0702' => { descr: 'Friends Book Fund', fund: 'E9995-FPUL-no program', external_id: '41172|E9995' },
    'H0703' => { descr: 'FR of Library Anniversary Fund', fund: 'E3612-FPUL-no program', external_id: '41172|E3612' },
    'H0750' => { descr: 'Robert Hill Taylor', fund: 'E4489-Spec Coll-no program', external_id: '41168|E4489' },
    'H0751' => { descr: 'Barksdale-Dabney-Henry Mem', fund: 'E0478-Spec Coll-no program', external_id: '41168|E0478' },
    'H0753' => { descr: 'Book Adoption', fund: 'AN561-Spec Coll', external_id: '41168|E9995|AN561' },
    'H0754' => { descr: 'Maxwell K/Portugal Res', fund: 'E3499-Spec Coll-no program', external_id: '41168|E3499' },
    'H0755' => { descr: 'Schein', fund: 'AN564-Spec Coll', external_id: '41168|E9995|AN564' },
    'H0756' => { descr: 'Pres Discretionary Gifts-Multi', fund: 'B0684-Spec Coll-no program', external_id: '41168|B0684' },
    'H0757' => { descr: 'FR of the Library', fund: 'E3025-FPUL-no program', external_id: '41172|E3025' },
    'H0758' => { descr: 'FR of the Library', fund: 'E3025-FPUL-no program', external_id: '41172|E3025' },
    'H0803' => { descr: 'Ludwig', fund: 'AN558-Spec Coll', external_id: '41168|E9995|AN558' },
    'H0950' => { descr: 'Leonard Milberg Gift', fund: 'B0875-Spec Coll-no program', external_id: '41168|B0875' },
    'H0951' => { descr: "Millberg '53 Irish Letters", fund: 'E3470-Spec Coll-no program', external_id: '41168|E3470' },
    'H1003' => { descr: 'Rockey', fund: 'AN557-Spec Coll', external_id: '41168|E9995|AN557' }
  }
end

def supplier_id_vndr_loc
  {
    '0000000003' => 'L0001',
    '0000000011' => 'L0001',
    '0000000013' => 'L0001',
    '0000000024' => 'L0001',
    '0000000052' => 'L0001',
    '0000000077' => 'L0001',
    '0000000078' => 'L0001',
    '0000000506' => 'L0001',
    '0000000640' => 'L0001',
    '0000000661' => 'L0001',
    '0000000680' => 'L0001',
    '0000000682' => 'L0001',
    '0000000698' => 'L0001',
    '0000000789' => 'L0001',
    '0000000791' => 'L0001',
    '0000000792' => 'L0001',
    '0000000819' => 'L0001',
    '0000000846' => 'L0001',
    '0000000854' => 'L0001',
    '0000000870' => 'L0001',
    '0000000873' => 'L0001',
    '0000000895' => 'L0001',
    '0000000932' => 'L0001',
    '0000001006' => 'L0001',
    '0000001223' => 'L0001',
    '0000001271' => 'L0001',
    '0000001285' => 'L0001',
    '0000001298' => 'L0001',
    '0000001303' => 'L0001',
    '0000001323' => 'L0001',
    '0000001355' => 'L0001',
    '0000001391' => 'L0001',
    '0000001401' => 'L0001',
    '0000001410' => 'L0001',
    '0000001525' => 'L0001',
    '0000001569' => 'L0001',
    '0000001698' => 'L0001',
    '0000001827' => 'L0001',
    '0000001858' => 'L0001',
    '0000002071' => 'L0001',
    '0000002444' => 'L0001',
    '0000002630' => 'L0001',
    '0000002635' => 'L0001',
    '0000002731' => 'L0001',
    '0000002736' => 'L0001',
    '0000002806' => 'L0001',
    '0000002822' => 'L0001',
    '0000002835' => 'L0001',
    '0000002851' => 'L0001',
    '0000002865' => 'L0001',
    '0000002875' => 'L0001',
    '0000002876' => 'L0001',
    '0000002970' => 'L0001',
    '0000003081' => 'L0001',
    '0000003272' => 'L0001',
    '0000003294' => 'L0001',
    '0000003400' => 'L0001',
    '0000003483' => 'L0001',
    '0000003609' => 'L0001',
    '0000003712' => 'L0001',
    '0000003723' => 'L0001',
    '0000003740' => 'L0001',
    '0000003801' => 'L0001',
    '0000003876' => 'L0001',
    '0000004066' => 'L0001',
    '0000004146' => 'L0001',
    '0000004170' => 'L0001',
    '0000004309' => 'L0001',
    '0000004328' => 'L0001',
    '0000004395' => 'L0001',
    '0000004396' => 'L0001',
    '0000004402' => 'L0001',
    '0000004592' => 'L0001',
    '0000004657' => 'L0001',
    '0000004731' => 'L0001',
    '0000004748' => 'L0001',
    '0000004752' => 'L0001',
    '0000004853' => 'L0001',
    '0000004858' => 'L0001',
    '0000004939' => 'L0001',
    '0000004941' => 'L0001',
    '0000004960' => 'L0001',
    '0000005322' => 'L0001',
    '0000005423' => 'L0001',
    '0000005425' => 'L0001',
    '0000005788' => 'L0001',
    '0000006012' => 'L0001',
    '0000006134' => 'L0001',
    '0000006190' => 'L0001',
    '0000006254' => 'L0001',
    '0000006322' => 'L0001',
    '0000006332' => 'L0001',
    '0000006444' => 'L0001',
    '0000006530' => 'L0001',
    '0000006637' => 'L0001',
    '0000006656' => 'L0001',
    '0000006684' => 'L0001',
    '0000007123' => 'L0001',
    '0000007372' => 'L0001',
    '0000007396' => 'L0001',
    '0000007404' => 'L0001',
    '0000007433' => 'L0001',
    '0000007610' => 'L0001',
    '0000007642' => 'L0001',
    '0000007712' => 'L0001',
    '0000007748' => 'L0001',
    '0000007969' => 'L0001',
    '0000008279' => 'L0001',
    '0000008307' => 'L0001',
    '0000008581' => 'L0001',
    '0000008661' => 'L0001',
    '0000008662' => 'L0001',
    '0000008663' => 'L0001',
    '0000008791' => 'L0001',
    '0000008792' => 'L0001',
    '0000009195' => 'L0001',
    '0000009492' => 'L0001',
    '0000009556' => 'L0001',
    '0000009557' => 'L0001',
    '0000009670' => 'L0001',
    '0000009671' => 'L0001',
    '0000009839' => 'L0001',
    '0000009859' => 'L0001',
    '0000009916' => 'L0001',
    '0000009924' => 'L0001',
    '0000010009' => 'L0001',
    '0000010148' => 'L0001',
    '0000010205' => 'L0001',
    '0000010239' => 'L0001',
    '0000010326' => 'L0001',
    '0000010327' => 'L0001',
    '0000010328' => 'L0001',
    '0000010401' => 'L0001',
    '0000010446' => 'L0001',
    '0000010467' => 'L0001',
    '0000010503' => 'L0001',
    '0000010575' => 'L0001',
    '0000010633' => 'L0001',
    '0000010711' => 'L0001',
    '0000010767' => 'L0001',
    '0000010768' => 'L0001',
    '0000010826' => 'L0001',
    '0000010953' => 'L0001',
    '0000010969' => 'L0001',
    '0000011102' => 'L0001',
    '0000011179' => 'L0001',
    '0000011185' => 'L0001',
    '0000011192' => 'L0001',
    '0000011290' => 'L0001',
    '0000011294' => 'L0001',
    '0000011326' => 'L0001',
    '0000011437' => 'L0001',
    '0000011448' => 'L0001',
    '0000011498' => 'L0001',
    '0000011534' => 'L0001',
    '0000011660' => 'L0001',
    '0000011687' => 'L0001',
    '0000011818' => 'L0001',
    '0000011820' => 'L0001',
    '0000011822' => 'L0001',
    '0000011842' => 'L0001',
    '0000011883' => 'L0001',
    '0000011962' => 'L0001',
    '0000012088' => 'L0001',
    '0000012091' => 'L0001',
    '0000012094' => 'L0001',
    '0000012136' => 'L0001',
    '0000012160' => 'L0001',
    '0000012241' => 'L0001',
    '0000012413' => 'L0001',
    '0000012548' => 'L0001',
    '0000012549' => 'L0001',
    '0000013038' => 'L0001',
    '0000013154' => 'L0001',
    '0000013192' => 'L0001',
    '0000013193' => 'L0001',
    '0000013244' => 'L0001',
    '0000013318' => 'L0001',
    '0000013385' => 'L0001',
    '0000013490' => 'L0001',
    '0000013552' => 'L0001',
    '0000013794' => 'L0001',
    '0000013831' => 'L0001',
    '0000013913' => 'L0001',
    '0000013987' => 'L0001',
    '0000013989' => 'L0001',
    '0000013990' => 'L0001',
    '0000014048' => 'L0002',
    '0000014082' => 'L0001',
    '0000014107' => 'L0001',
    '0000014128' => 'L0001',
    '0000014229' => 'L0001',
    '0000014310' => 'L0001',
    '0000014430' => 'L0001',
    '0000014431' => 'L0001',
    '0000014592' => 'L0001',
    '0000014603' => 'L0001',
    '0000014622' => 'L0001',
    '0000014632' => 'L0001',
    '0000014699' => 'L0001',
    '0000014766' => 'L0001',
    '0000014845' => 'L0001',
    '0000014888' => 'L0001',
    '0000014889' => 'L0001',
    '0000014892' => 'L0002',
    '0000014915' => 'L0001',
    '0000014970' => 'L0001',
    '0000015035' => 'L0001',
    '0000015036' => 'L0001',
    '0000015040' => 'L0001',
    '0000015041' => 'L0001',
    '0000015101' => 'L0001',
    '0000015121' => 'L0001',
    '0000015124' => 'L0001',
    '0000015126' => 'L0001',
    '0000015185' => 'L0001',
    '0000015326' => 'L0001',
    '0000015352' => 'L0001',
    '0000015483' => 'L0001',
    '0000015506' => 'L0001',
    '0000015526' => 'L0001',
    '0000015620' => 'L0001',
    '0000015627' => 'L0001',
    '0000015756' => 'L0001',
    '0000015818' => 'L0001',
    '0000015838' => 'L0001',
    '0000015843' => 'L0002',
    '0000015870' => 'L0001',
    '0000015931' => 'L0001',
    '0000016006' => 'L0001',
    '0000016128' => 'L0001',
    '0000016131' => 'L0001',
    '0000016176' => 'L0001',
    '0000016279' => 'L0001',
    '0000016281' => 'L0001',
    '0000016291' => 'L0001',
    '0000016475' => 'L0001',
    '0000016504' => 'L0001',
    '0000016580' => 'L0001',
    '0000016581' => 'L0001',
    '0000016607' => 'L0002',
    '0000016732' => 'L0001',
    '0000016793' => 'L0001',
    '0000016876' => 'L0001',
    '0000016920' => 'L0001',
    '0000016921' => 'L0001',
    '0000016953' => 'L0001',
    '0000016962' => 'L0002',
    '0000017094' => 'L0001',
    '0000017098' => 'L0001',
    '0000017180' => 'L0001',
    '0000017188' => 'L0001',
    '0000017209' => 'L0001',
    '0000017241' => 'L0001',
    '0000017310' => 'L0001',
    '0000017406' => 'L0001',
    '0000017437' => 'L0001',
    '0000017627' => 'L0001',
    '0000017639' => 'L0001',
    '0000017811' => 'L0001',
    '0000017812' => 'L0001',
    '0000017866' => 'L0001',
    '0000017911' => 'L0001',
    '0000018012' => 'L0001',
    '0000018442' => 'L0001',
    '0000018498' => 'L0001',
    '0000018709' => 'L0001',
    '0000019026' => 'L0001',
    '0000019117' => 'L0001',
    '0000019161' => 'L0001',
    '0000019194' => 'L0001',
    '0000019360' => 'L0001',
    '0000019512' => 'L0001',
    '0000019532' => 'L0001',
    '0000019667' => 'L0001',
    '0000019816' => 'L0001',
    '0000020304' => 'L0001',
    '0000020434' => 'L0001',
    '0000020574' => 'L0001',
    '0000020715' => 'L0001',
    '0000020774' => 'L0001',
    '0000020890' => 'L0001',
    '0000020985' => 'L0001',
    '0000021149' => 'L0001',
    '0000021151' => 'L0001',
    '0000021248' => 'L0001',
    '0000021278' => 'L0001',
    '0000021440' => 'L0001',
    '0000021493' => 'L0004',
    '0000021606' => 'L0001',
    '0000021660' => 'L0001',
    '0000021688' => 'L0001',
    '0000021771' => 'L0001',
    '0000021901' => 'L0001',
    '0000021902' => 'L0001',
    '0000021903' => 'L0001',
    '0000021908' => 'L0001',
    '0000022013' => 'L0001',
    '0000022060' => 'L0001',
    '0000022209' => 'L0001',
    '0000022241' => 'L0001',
    '0000022266' => 'L0001',
    '0000022274' => 'L0001',
    '0000022296' => 'L0001',
    '0000022383' => 'L0001',
    '0000022397' => 'L0001',
    '0000022415' => 'L0001',
    '0000022426' => 'L0001',
    '0000022507' => 'L0001',
    '0000022518' => 'L0001',
    '0000022599' => 'L0001',
    '0000022601' => 'L0001',
    '0000022703' => 'L0001',
    '0000022795' => 'L0001',
    '0000022796' => 'L0001',
    '0000022851' => 'L0001',
    '0000023042' => 'L0001',
    '0000023113' => 'L0001',
    '0000023116' => 'L0001',
    '0000023162' => 'L0001',
    '0000023360' => 'L0001',
    '0000023365' => 'L0001',
    '0000023645' => 'L0001',
    '0000023693' => 'L0001',
    '0000023732' => 'L0001',
    '0000023761' => 'L0001',
    '0000023791' => 'L0001',
    '0000023810' => 'L0001',
    '0000023867' => 'L0001',
    '0000023934' => 'L0001',
    '0000023939' => 'L0001',
    '0000023943' => 'L0001',
    '0000023977' => 'L0001',
    '0000024366' => 'L0001',
    '0000024439' => 'L0001',
    '0000024466' => 'L0001',
    '0000024512' => 'L0001',
    '0000024555' => 'L0001',
    '0000024556' => 'L0001',
    '0000024558' => 'L0001',
    '0000024614' => 'L0001',
    '0000024665' => 'L0001',
    '0000024686' => 'L0001',
    '0000024791' => 'L0001',
    '0000024797' => 'L0001',
    '0000024858' => 'L0001',
    '0000024900' => 'L0001',
    '0000024929' => 'L0001',
    '0000025011' => 'L0001',
    '0000025020' => 'L0001',
    '0000025041' => 'L0001',
    '0000025051' => 'L0001',
    '0000025055' => 'L0001',
    '0000025445' => 'L0001',
    '0000025461' => 'L0001',
    '0000025561' => 'L0001',
    '0000025571' => 'L0001',
    '0000025575' => 'L0001',
    '0000026074' => 'L0001',
    '0000026113' => 'L0001',
    '0000026270' => 'L0001',
    '0000026294' => 'L0001',
    '0000026502' => 'L0001',
    '0000026505' => 'L0001',
    '0000026506' => 'L0001',
    '0000026509' => 'L0001',
    '0000026632' => 'L0001',
    '0000026643' => 'L0001',
    '0000026648' => 'L0001',
    '0000026681' => 'L0001',
    '0000026893' => 'L0001',
    '0000026894' => 'L0001',
    '0000026903' => 'L0001',
    '0000026945' => 'L0001',
    '0000026967' => 'L0001',
    '0000026995' => 'L0001',
    '0000027219' => 'L0001',
    '0000027329' => 'L0001',
    '0000027452' => 'L0001',
    '0000027462' => 'L0001',
    '0000027503' => 'L0001',
    '0000027583' => 'L0001',
    '0000027813' => 'L0001',
    '0000028021' => 'L0001',
    '0000028095' => 'L0001',
    '0000028421' => 'L0001',
    '0000028685' => 'L0001',
    '0000028690' => 'L0001',
    '0000028770' => 'L0001',
    '0000028938' => 'L0001',
    '0000029069' => 'L0001',
    '0000029223' => 'L0001',
    '0000029419' => 'L0001',
    '0000029692' => 'L0001',
    '0000029693' => 'L0001',
    '0000029703' => 'L0001',
    '0000029792' => 'L0001',
    '0000029795' => 'L0001',
    '0000029811' => 'L0001',
    '0000029849' => 'L0001',
    '0000029923' => 'L0001',
    '0000030048' => 'L0001',
    '0000030049' => 'L0001',
    '0000030194' => 'L0001',
    '0000030335' => 'L0001',
    '0000030357' => 'L0001',
    '0000030404' => 'L0001',
    '0000030440' => 'L0001',
    '0000030491' => 'L0001',
    '0000030641' => 'L0001',
    '0000030663' => 'L0001',
    '0000030708' => 'L0001',
    '0000030763' => 'L0001',
    '0000030842' => 'L0001',
    '0000030919' => 'L0001',
    '0000030929' => 'L0001',
    '0000030961' => 'L0001',
    '0000031054' => 'L0001',
    '0000031056' => 'L0001',
    '0000031142' => 'L0001',
    '0000031143' => 'L0001',
    '0000031243' => 'L0001',
    '0000031322' => 'L0001',
    '0000031337' => 'L0001',
    '0000031498' => 'L0001',
    '0000031522' => 'L0001',
    '0000031530' => 'L0001',
    '0000031531' => 'L0001',
    '0000031609' => 'L0001',
    '0000031748' => 'L0001',
    '0000031772' => 'L0001',
    '0000031791' => 'L0001',
    '0000031913' => 'L0001',
    '0000031948' => 'L0001',
    '0000031965' => 'L0001',
    '0000032143' => 'L0001',
    '0000032144' => 'L0001',
    '0000032203' => 'L0001',
    '0000032219' => 'L0001',
    '0000032361' => 'L0001',
    '0000032394' => 'L0001',
    '0000032472' => 'L0001',
    '0000032494' => 'L0001',
    '0000032503' => 'L0001',
    '0000032527' => 'L0001',
    '0000032557' => 'L0001',
    '0000032624' => 'L0001',
    '0000032638' => 'L0001',
    '0000032707' => 'L0001',
    '0000032746' => 'L0001',
    '0000032904' => 'L0001',
    '0000032916' => 'L0001',
    '0000032918' => 'L0001',
    '0000032919' => 'L0001',
    '0000033096' => 'L0001',
    '0000033168' => 'L0001',
    '0000033172' => 'L0001',
    '0000033175' => 'L0001',
    '0000033192' => 'L0001',
    '0000033210' => 'L0001',
    '0000033228' => 'L0001',
    '0000033401' => 'L0002',
    '0000033555' => 'L0001',
    '0000033696' => 'L0001',
    '0000033745' => 'L0001',
    '0000033810' => 'L0001',
    '0000033823' => 'L0001',
    '0000033827' => 'L0001',
    '0000033872' => 'L0001',
    '0000033986' => 'L0001',
    '0000033994' => 'L0001',
    '0000034086' => 'L0001',
    '0000034260' => 'L0001',
    '0000034332' => 'L0001',
    '0000034335' => 'L0001',
    '0000034362' => 'L0001',
    '0000034410' => 'L0001',
    '0000034487' => 'L0001',
    '0000034692' => 'L0001',
    '0000034788' => 'L0001',
    '0000034804' => 'L0001',
    '0000034897' => 'L0001',
    '0000035437' => 'L0001',
    '0000035679' => 'L0001',
    '0000035883' => 'L0001',
    '0000036024' => 'L0001',
    '0000036104' => 'L0001',
    '0000036210' => 'L0001',
    '0000036238' => 'L0001',
    '0000036247' => 'L0001',
    '0000036266' => 'L0001',
    '0000036267' => 'L0001',
    '0000036285' => 'L0001',
    '0000036286' => 'L0001',
    '0000036302' => 'L0001',
    '0000036372' => 'L0001',
    '0000036411' => 'L0001',
    '0000036441' => 'L0001',
    '0000036456' => 'L0001',
    '0000036545' => 'L0001',
    '0000036655' => 'L0001',
    '0000036681' => 'L0001',
    '0000036684' => 'L0001',
    '0000036721' => 'L0001',
    '0000036747' => 'L0001',
    '0000036797' => 'L0001',
    '0000036828' => 'L0001',
    '0000036878' => 'L0001',
    '0000036886' => 'L0001',
    '0000036904' => 'L0001',
    '0000036950' => 'L0001',
    '0000037012' => 'L0001',
    '0000037057' => 'L0001',
    '0000037138' => 'L0001',
    '0000037161' => 'L0001',
    '0000037166' => 'L0001',
    '0000037283' => 'L0001',
    '0000037388' => 'L0001',
    '0000037430' => 'L0001',
    '0000037514' => 'L0001',
    '0000037525' => 'L0001',
    '0000037548' => 'L0001',
    '0000037646' => 'L0001',
    '0000037754' => 'L0001',
    '0000037820' => 'L0001',
    '0000037843' => 'L0001',
    '0000037876' => 'L0001',
    '0000037923' => 'L0001',
    '0000037940' => 'L0001',
    '0000037952' => 'L0001',
    '0000037970' => 'L0001',
    '0000038186' => 'L0001',
    '0000038357' => 'L0001',
    '0000038369' => 'L0001',
    '0000038416' => 'L0001',
    '0000038430' => 'L0001',
    '0000038437' => 'L0001',
    '0000038439' => 'L0001',
    '0000038456' => 'L0001',
    '0000038458' => 'L0001',
    '0000038510' => 'L0001',
    '0000038528' => 'L0001',
    '0000038598' => 'L0001',
    '0000038615' => 'L0001',
    '0000038651' => 'L0001',
    '0000038670' => 'L0001',
    '0000038718' => 'L0001',
    '0000038747' => 'L0001',
    '0000038763' => 'L0001',
    '0000038776' => 'L0001',
    '0000038812' => 'L0001',
    '0000038835' => 'L0001',
    '0000038836' => 'L0001',
    '0000038955' => 'L0001',
    '0000038966' => 'L0001',
    '0000039031' => 'L0001',
    '0000039035' => 'L0001',
    '0000039039' => 'L0001',
    '0000039120' => 'L0001',
    '0000039203' => 'L0001',
    '0000039226' => 'L0001',
    '0000039277' => 'L0001',
    '0000039390' => 'L0001',
    '0000039453' => 'L0001',
    '0000039500' => 'L0001',
    '0000039600' => 'L0001',
    '0000039602' => 'L0001',
    '0000039895' => 'L0001',
    '0000040095' => 'L0001',
    '0000040115' => 'L0001',
    '0000040137' => 'L0001',
    '0000040302' => 'L0001',
    '0000040305' => 'L0001',
    '0000040329' => 'L0001',
    '0000040403' => 'L0001',
    '0000040409' => 'L0001',
    '0000040426' => 'L0001',
    '0000040430' => 'L0001',
    '0000040468' => 'L0001',
    '0000040532' => 'L0001',
    '0000040610' => 'L0001',
    '0000040644' => 'L0001',
    '0000040654' => 'L0001',
    '0000040698' => 'L0001',
    '0000040723' => 'L0001',
    '0000040744' => 'L0001',
    '0000040773' => 'L0001',
    '0000040790' => 'L0001',
    '0000040901' => 'L0001',
    '0000040902' => 'L0001',
    '0000040918' => 'L0001',
    '0000040938' => 'L0001',
    '0000041038' => 'L0001',
    '0000041047' => 'L0001',
    '0000041071' => 'L0001',
    '0000041203' => 'L0001',
    '0000041218' => 'L0001',
    '0000041392' => 'L0001',
    '0000041632' => 'L0001',
    '0000041697' => 'L0001',
    '0000041703' => 'L0001',
    '0000041781' => 'L0001',
    '0000041797' => 'L0001',
    '0000041832' => 'L0001',
    '0000041845' => 'L0001',
    '0000041887' => 'L0001',
    '0000041914' => 'L0001',
    '0000041939' => 'L0001',
    '0000041975' => 'L0001',
    '0000042005' => 'L0001',
    '0000042072' => 'L0001',
    '0000042097' => 'L0001',
    '0000042120' => 'L0001',
    '0000042122' => 'L0001',
    '0000042186' => 'L0001',
    '0000042217' => 'L0001',
    '0000042234' => 'L0001',
    '0000042281' => 'L0001',
    '000132071' => 'L0001',
    '010000909' => 'L0001',
    '010005596' => 'L0001',
    '020000175' => 'L0001',
    '020000271' => 'L0001',
    '020001440' => 'L0001',
    '020002089' => 'L0001',
    '020003000' => 'L0001',
    '020003593' => 'L0001',
    '020004008' => 'L0001',
    '020006106' => 'L0001',
    '020095831' => 'L0001',
    '020099161' => 'L0001',
    '020106279' => 'L0001',
    '020113253' => 'L0001',
    '020116420' => 'L0001',
    '110068055' => 'L0001',
    '150003302' => 'L0001',
    '150004933' => 'L0001',
    '150005645' => 'L0001',
    '150006070' => 'L0001',
    '150006277' => 'L0001',
    '150006522' => 'L0001',
    '150007432' => 'L0001',
    '150007625' => 'L0001',
    '150008083' => 'L0001',
    '150020259' => 'L0001',
    '150020792' => 'L0001',
    '150020848' => 'L0001',
    '150020886' => 'L0001',
    '150021428' => 'L0001',
    '150021923' => 'L0001',
    '150024766' => 'L0001',
    '150025737' => 'L0001',
    '150026044' => 'L0001',
    '150026138' => 'L0001',
    '150026374' => 'L0001',
    '150026628' => 'L0001',
    '150026845' => 'L0001',
    '150027284' => 'L0001',
    '150028373' => 'L0001',
    '150030324' => 'L0001',
    '150031451' => 'L0001',
    '150032417' => 'L0001',
    '150033718' => 'L0001',
    '150035854' => 'L0001',
    '150036081' => 'L0001',
    '150038037' => 'L0001',
    '150039456' => 'L0001',
    '150039649' => 'L0001',
    '150040059' => 'L0001',
    '150041445' => 'L0001',
    '150046565' => 'L0001',
    '150050666' => 'L0001',
    '150055640' => 'L0001',
    '150055673' => 'L0001',
    '150056818' => 'L0001',
    '150072300' => 'L0001',
    '150072498' => 'L0001',
    '150081417' => 'L0001',
    '150081653' => 'L0001',
    '150082530' => 'L0001',
    '150084265' => 'L0001',
    '150087433' => 'L0001',
    '150089823' => 'L0001',
    '150092623' => 'L0001',
    '150093062' => 'L0001',
    '150093684' => 'L0001',
    '150101109' => 'L0002',
    '150101307' => 'L0001',
    '150101816' => 'L0001',
    '150103971' => 'L0001',
    '150105013' => 'L0001',
    '150108035' => 'L0001',
    '150115516' => 'L0001',
    '150116313' => 'L0001',
    '150117162' => 'L0001',
    '150118185' => 'L0001',
    '150118519' => 'L0001',
    '150121541' => 'L0001',
    '150123653' => 'L0001',
    '150128278' => 'L0001',
    '150128405' => 'L0001',
    '150129551' => 'L0001',
    '150129961' => 'L0003',
    '150130154' => 'L0001',
    '150130550' => 'L0001',
    '150131276' => 'L0001',
    '150131540' => 'L0001',
    '150133402' => 'L0001',
    '150133784' => 'L0001',
    '150136009' => 'L0001',
    '150136071' => 'L0001',
    '250000846' => 'L0001',
    '250003227' => 'L0001',
    '250005099' => 'L0001',
    '250005108' => 'L0001',
    '250005419' => 'L0001',
    '250005848' => 'L0001',
    '250006042' => 'L0001',
    '250006216' => 'L0001',
    '250006240' => 'L0001',
    '250006485' => 'L0001',
    '250006546' => 'L0001',
    '250006565' => 'L0001',
    '250007574' => 'L0001',
    '250020335' => 'L0001',
    '250020811' => 'L0001',
    '250020910' => 'L0001',
    '250021090' => 'L0001',
    '250021113' => 'L0001',
    '250021419' => 'L0001',
    '250021792' => 'L0001',
    '250021933' => 'L0001',
    '250022103' => 'L0001',
    '250022546' => 'L0001',
    '250023494' => 'L0001',
    '250023828' => 'L0001',
    '250025653' => 'L0001',
    '250025813' => 'L0001',
    '250025870' => 'L0001',
    '250026134' => 'L0001',
    '250027011' => 'L0001',
    '250030711' => 'L0001',
    '250031423' => 'L0001',
    '250031866' => 'L0001',
    '250035609' => 'L0001',
    '250036029' => 'L0001',
    '250040738' => 'L0001',
    '250043572' => 'L0001',
    '250046028' => 'L0001',
    '250049842' => 'L0001',
    '250049889' => 'L0001',
    '250050313' => 'L0001',
    '250052637' => 'L0001',
    '250052802' => 'L0001',
    '250053778' => 'L0001',
    '250054815' => 'L0001',
    '250054928' => 'L0001',
    '250061613' => 'L0001',
    '250065545' => 'L0001',
    '250066125' => 'L0001',
    '250066318' => 'L0001',
    '250067506' => 'L0001',
    '250071551' => 'L0001',
    '250076077' => 'L0001',
    '250076666' => 'L0001',
    '250078316' => 'L0001',
    '250083087' => 'L0001',
    '250084025' => 'L0001',
    '250086316' => 'L0001',
    '250089828' => 'L0001',
    '250090827' => 'L0001',
    '250091186' => 'L0001',
    '250092699' => 'L0001',
    '250093232' => 'L0001',
    '250095278' => 'L0001',
    '250095971' => 'L0001',
    '250096080' => 'L0001',
    '250097098' => 'L0001',
    '250098724' => 'L0001',
    '250100049' => 'L0001',
    '250102053' => 'L0001',
    '250104231' => 'L0001',
    '250106715' => 'L0001',
    '250107512' => 'L0001',
    '250108238' => 'L0001',
    '250108337' => 'L0001',
    '250108959' => 'L0001',
    '250111712' => 'L0001',
    '250111858' => 'L0001',
    '250112556' => 'L0001',
    '250119359' => 'L0001',
    '250119425' => 'L0001',
    '250119538' => 'L0001',
    '250121080' => 'L0001',
    '250121810' => 'L0001',
    '250122494' => 'L0001',
    '250122569' => 'L0001',
    '250124653' => 'L0001',
    '250125191' => 'L0001',
    '250126454' => 'L0001',
    '250127270' => 'L0001',
    '250128203' => 'L0001',
    '250128858' => 'L0001',
    '250128938' => 'L0001',
    '250128981' => 'L0001',
    '250129306' => 'L0001',
    '250129693' => 'L0001',
    '250130404' => 'L0001',
    '250130800' => 'L0001',
    '250130965' => 'L0001',
    '250131352' => 'L0001',
    '250131644' => 'L0001',
    '250133624' => 'L0001',
    '250134058' => 'L0001',
    '250134096' => 'L0001',
    '250134883' => 'L0001',
    '250136392' => 'L0001',
    '250136401' => 'L0001',
    '250136514' => 'L0001',
    '250136797' => 'L0001',
    '350000102' => 'L0001',
    '350001361' => 'L0001',
    '350001540' => 'L0001',
    '350002431' => 'L0001',
    '350002841' => 'L0001',
    '350004199' => 'L0001',
    '350004307' => 'L0001',
    '350004986' => 'L0001',
    '350005156' => 'L0001',
    '350005255' => 'L0001',
    '350005415' => 'L0001',
    '350005731' => 'L0001',
    '350005778' => 'L0001',
    '350005910' => 'L0001',
    '350005919' => 'L0001',
    '350005962' => 'L0001',
    '350006325' => 'L0001',
    '350006655' => 'L0002',
    '350006933' => 'L0001',
    '350007188' => 'L0001',
    '350007499' => 'L0001',
    '350007626' => 'L0001',
    '350008051' => 'L0001',
    '350020345' => 'L0001',
    '350020849' => 'L0001',
    '350020887' => 'L0001',
    '350021269' => 'L0001',
    '350021302' => 'L0001',
    '350021415' => 'L0001',
    '350021420' => 'L0001',
    '350021844' => 'L0001',
    '350022617' => 'L0001',
    '350022622' => 'L0001',
    '350022716' => 'L0001',
    '350023819' => 'L0001',
    '350025606' => 'L0001',
    '350026375' => 'L0001',
    '350026629' => 'L0001',
    '350028124' => 'L0001',
    '350030344' => 'L0001',
    '350033823' => 'L0001',
    '350033969' => 'L0001',
    '350034808' => 'L0001',
    '350040046' => 'L0001',
    '350040998' => 'L0001',
    '350042403' => 'L0001',
    '350044157' => 'L0001',
    '350044515' => 'L0001',
    '350048782' => 'L0001',
    '350048862' => 'L0001',
    '350049800' => 'L0001',
    '350049890' => 'L0001',
    '350050125' => 'L0001',
    '350051525' => 'L0001',
    '350052416' => 'L0001',
    '350053774' => 'L0001',
    '350058088' => 'L0001',
    '350063297' => 'L0001',
    '350064980' => 'L0001',
    '350065362' => 'L0001',
    '350065833' => 'L0001',
    '350067790' => 'L0001',
    '350072315' => 'L0001',
    '350080650' => 'L0001',
    '350081913' => 'L0001',
    '350081979' => 'L0001',
    '350084638' => 'L0001',
    '350086251' => 'L0001',
    '350087707' => 'L0001',
    '350089042' => 'L0001',
    '350089414' => 'L0001',
    '350089513' => 'L0001',
    '350089782' => 'L0001',
    '350090116' => 'L0001',
    '350091295' => 'L0001',
    '350092737' => 'L0001',
    '350094463' => 'L0001',
    '350094755' => 'L0001',
    '350098305' => 'L0001',
    '350098494' => 'L0001',
    '350100361' => 'L0001',
    '350100733' => 'L0001',
    '350102746' => 'L0001',
    '350103510' => 'L0001',
    '350109648' => 'L0001',
    '350110110' => 'L0001',
    '350113151' => 'L0001',
    '350115145' => 'L0001',
    '350115517' => 'L0001',
    '350117106' => 'L0001',
    '350117898' => 'L0001',
    '350118351' => 'L0001',
    '350119195' => 'L0001',
    '350119360' => 'L0001',
    '350120962' => 'L0001',
    '350121561' => 'L0001',
    '350122744' => 'L0001',
    '350123536' => 'L0001',
    '350123753' => 'L0001',
    '350124564' => 'L0001',
    '350124606' => 'L0001',
    '350124630' => 'L0001',
    '350125106' => 'L0001',
    '350127181' => 'L0001',
    '350129104' => 'L0001',
    '350129335' => 'L0001',
    '350129373' => 'L0001',
    '350129509' => 'L0001',
    '350129962' => 'L0001',
    '350131084' => 'L0001',
    '350131107' => 'L0001',
    '350131296' => 'L0001',
    '350131927' => 'L0001',
    '350133177' => 'L0001',
    '350134035' => 'L0001',
    '350138891' => 'L0001',
    '450000051' => 'L0001',
    '450000791' => 'L0001',
    '450001399' => 'L0001',
    '450002752' => 'L0001',
    '450003987' => 'L0001',
    '450005482' => 'L0001',
    '450005618' => 'L0001',
    '450005816' => 'L0001',
    '450005986' => 'L0001',
    '450006175' => 'L0001',
    '450006189' => 'L0001',
    '450006217' => 'L0001',
    '450006288' => 'L0001',
    '450006877' => 'L0001',
    '450008315' => 'L0001',
    '450020374' => 'L0001',
    '450020609' => 'L0001',
    '450020708' => 'L0004',
    '450020850' => 'L0001',
    '450020897' => 'L0001',
    '450021251' => 'L0001',
    '450021967' => 'L0001',
    '450022118' => 'L0001',
    '450022552' => 'L0001',
    '450027205' => 'L0001',
    '450027281' => 'L0001',
    '450032513' => 'L0001',
    '450033715' => 'L0001',
    '450035295' => 'L0001',
    '450040428' => 'L0001',
    '450040763' => 'L0001',
    '450046128' => 'L0001',
    '450050451' => 'L0001',
    '450050507' => 'L0001',
    '450052987' => 'L0001',
    '450053242' => 'L0001',
    '450053897' => 'L0001',
    '450056424' => 'L0006',
    '450057169' => 'L0001',
    '450062929' => 'L0001',
    '450069775' => 'L0001',
    '450072344' => 'L0001',
    '450073937' => 'L0001',
    '450074522' => 'L0001',
    '450079048' => 'L0001',
    '450083041' => 'L0001',
    '450085742' => 'L0001',
    '450086058' => 'L0001',
    '450088241' => 'L0001',
    '450090112' => 'L0001',
    '450090791' => 'L0001',
    '450092045' => 'L0001',
    '450094666' => 'L0001',
    '450099847' => 'L0001',
    '450101196' => 'L0001',
    '450104053' => 'L0001',
    '450106179' => 'L0001',
    '450106283' => 'L0001',
    '450111468' => 'L0001',
    '450111633' => 'L0001',
    '450115805' => 'L0001',
    '450116927' => 'L0001',
    '450117465' => 'L0001',
    '450118983' => 'L0001',
    '450120505' => 'L0001',
    '450122481' => 'L0001',
    '450123565' => 'L0001',
    '450128063' => 'L0001',
    '450129510' => 'L0001',
    '450131103' => 'L0001',
    '450131857' => 'L0001',
    '450131989' => 'L0001',
    '450132809' => 'L0001',
    '450133069' => 'L0001',
    '450133993' => 'L0001',
    '450134568' => 'L0001',
    '450138010' => 'L0001',
    '550000598' => 'L0001',
    '550000895' => 'L0001',
    '550002140' => 'L0001',
    '550002371' => 'L0001',
    '550004954' => 'L0001',
    '550005063' => 'L0001',
    '550005708' => 'L0001',
    '550006213' => 'L0001',
    '550006359' => 'L0001',
    '550020775' => 'L0001',
    '550021831' => 'L0001',
    '550022463' => 'L0001',
    '550024773' => 'L0001',
    '550025202' => 'L0001',
    '550026376' => 'L0001',
    '550027060' => 'L0001',
    '550027606' => 'L0001',
    '550027611' => 'L0001',
    '550028158' => 'L0001',
    '550029209' => 'L0001',
    '550029332' => 'L0001',
    '550031189' => 'L0001',
    '550033819' => 'L0001',
    '550034159' => 'L0001',
    '550034899' => 'L0001',
    '550037662' => 'L0001',
    '550040716' => 'L0001',
    '550045459' => 'L0001',
    '550046025' => 'L0001',
    '550049721' => 'L0001',
    '550052205' => 'L0001',
    '550052417' => 'L0001',
    '550052799' => 'L0001',
    '550053775' => 'L0001',
    '550053780' => 'L0001',
    '550057377' => 'L0001',
    '550058292' => 'L0001',
    '550060540' => 'L0001',
    '550062218' => 'L0001',
    '550063072' => 'L0001',
    '550063623' => 'L0001',
    '550065071' => 'L0001',
    '550066824' => 'L0001',
    '550067319' => 'L0001',
    '550071072' => 'L0001',
    '550072038' => 'L0001',
    '550072500' => 'L0001',
    '550080241' => 'L0001',
    '550082080' => 'L0001',
    '550086483' => 'L0001',
    '550087303' => 'L0001',
    '550090824' => 'L0001',
    '550091791' => 'L0001',
    '550093808' => 'L0001',
    '550096680' => 'L0001',
    '550098792' => 'L0001',
    '550099301' => 'L0001',
    '550104322' => 'L0001',
    '550107306' => 'L0001',
    '550116645' => 'L0001',
    '550120322' => 'L0001',
    '550120336' => 'L0001',
    '550120421' => 'L0001',
    '550120614' => 'L0001',
    '550121675' => 'L0001',
    '550123815' => 'L0001',
    '550123933' => 'L0001',
    '550124023' => 'L0001',
    '550126757' => 'L0001',
    '550127648' => 'L0001',
    '550131085' => 'L0001',
    '550131419' => 'L0001',
    '550131438' => 'L0001',
    '550131641' => 'L0001',
    '550133178' => 'L0001',
    '550133461' => 'L0001',
    '550133668' => 'L0001',
    '550138251' => 'L0001',
    '650001758' => 'L0001',
    '650002046' => 'L0001',
    '650003116' => 'L0001',
    '650003861' => 'L0001',
    '650004111' => 'L0001',
    '650004879' => 'L0001',
    '650005134' => 'L0001',
    '650005332' => 'L0001',
    '650006218' => 'L0001',
    '650006355' => 'L0001',
    '650006369' => 'L0001',
    '650006685' => 'L0001',
    '650006727' => 'L0001',
    '650007072' => 'L0001',
    '650007991' => 'L0001',
    '650020097' => 'L0001',
    '650020752' => 'L0001',
    '650020785' => 'L0001',
    '650020799' => 'L0001',
    '650020808' => 'L0001',
    '650020879' => 'L0001',
    '650021266' => 'L0001',
    '650021426' => 'L0001',
    '650021973' => 'L0001',
    '650022105' => 'L0001',
    '650022473' => 'L0001',
    '650022614' => 'L0001',
    '650022727' => 'L0001',
    '650025655' => 'L0001',
    '650025735' => 'L0001',
    '650025740' => 'L0001',
    '650025928' => 'L0001',
    '650026122' => 'L0001',
    '650026631' => 'L0001',
    '650026819' => 'L0001',
    '650027946' => 'L0001',
    '650027951' => 'L0001',
    '650028022' => 'L0001',
    '650028564' => 'L0001',
    '650029502' => 'L0001',
    '650030011' => 'L0001',
    '650030699' => 'L0001',
    '650032024' => 'L0001',
    '650038968' => 'L0001',
    '650042160' => 'L0001',
    '650044093' => 'L0001',
    '650047671' => 'L0001',
    '650050508' => 'L0001',
    '650050659' => 'L0001',
    '650052484' => 'L0001',
    '650052936' => 'L0001',
    '650054054' => 'L0001',
    '650056439' => 'L0001',
    '650056760' => 'L0001',
    '650061361' => 'L0001',
    '650063317' => 'L0001',
    '650065863' => 'L0001',
    '650066636' => 'L0001',
    '650067023' => 'L0001',
    '650067546' => 'L0001',
    '650070987' => 'L0001',
    '650073373' => 'L0001',
    '650074184' => 'L0001',
    '650083777' => 'L0001',
    '650086182' => 'L0001',
    '650086691' => 'L0001',
    '650086785' => 'L0001',
    '650087596' => 'L0001',
    '650089430' => 'L0001',
    '650092480' => 'L0001',
    '650093390' => 'L0001',
    '650095148' => 'L0001',
    '650095247' => 'L0001',
    '650098759' => 'L0001',
    '650099542' => 'L0001',
    '650103587' => 'L0001',
    '650106284' => 'L0001',
    '650109433' => 'L0001',
    '650111832' => 'L0001',
    '650112134' => 'L0001',
    '650113303' => 'L0001',
    '650113355' => 'L0001',
    '650115806' => 'L0001',
    '650116071' => 'L0001',
    '650116575' => 'L0001',
    '650117843' => 'L0001',
    '650118461' => 'L0001',
    '650119272' => 'L0001',
    '650119757' => 'L0001',
    '650122929' => 'L0001',
    '650123392' => 'L0001',
    '650123646' => 'L0001',
    '650123919' => 'L0001',
    '650124198' => 'L0001',
    '650127154' => 'L0001',
    '650127611' => 'L0001',
    '650128064' => 'L0001',
    '650129530' => 'L0001',
    '650131104' => 'L0001',
    '650131429' => 'L0001',
    '650131467' => 'L0001',
    '650131858' => 'L0001',
    '650132311' => 'L0001',
    '650133532' => 'L0001',
    '650138765' => 'L0001',
    '750000434' => 'L0001',
    '750000938' => 'L0001',
    '750002989' => 'L0001',
    '750005417' => 'L0001',
    '750005474' => 'L0001',
    '750005686' => 'L0001',
    '750006577' => 'L0001',
    '750007223' => 'L0006',
    '750007501' => 'L0001',
    '750007671' => 'L0001',
    '750020880' => 'L0001',
    '750020903' => 'L0001',
    '750020917' => 'L0001',
    '750021125' => 'L0001',
    '750021158' => 'L0001',
    '750021262' => 'L0001',
    '750021950' => 'L0001',
    '750022558' => 'L0001',
    '750022619' => 'L0001',
    '750023473' => 'L0001',
    '750024774' => 'L0001',
    '750024948' => 'L0001',
    '750026127' => 'L0001',
    '750026132' => 'L0001',
    '750027466' => 'L0001',
    '750028131' => 'L0001',
    '750029531' => 'L0001',
    '750029578' => 'L0001',
    '750029917' => 'L0001',
    '750030021' => 'L0001',
    '750030101' => 'L0001',
    '750030643' => 'L0001',
    '750032251' => 'L0001',
    '750034283' => 'L0001',
    '750040793' => 'L0001',
    '750041632' => 'L0001',
    '750044418' => 'L0001',
    '750045451' => 'L0001',
    '750052635' => 'L0001',
    '750056440' => 'L0001',
    '750056586' => 'L0001',
    '750062196' => 'L0001',
    '750065072' => 'L0001',
    '750067207' => 'L0001',
    '750073477' => 'L0001',
    '750076711' => 'L0001',
    '750077847' => 'L0001',
    '750079050' => 'L0001',
    '750079210' => 'L0001',
    '750079474' => 'L0001',
    '750081133' => 'L0001',
    '750081397' => 'L0001',
    '750081901' => 'L0001',
    '750084268' => 'L0001',
    '750087709' => 'L0001',
    '750091226' => 'L0001',
    '750093809' => 'L0001',
    '750094762' => 'L0001',
    '750098166' => 'L0001',
    '750099698' => 'L0001',
    '750100443' => 'L0001',
    '750102051' => 'L0001',
    '750103427' => 'L0001',
    '750108269' => 'L0001',
    '750115251' => 'L0001',
    '750115519' => 'L0001',
    '750116274' => 'L0001',
    '750119621' => 'L0001',
    '750123920' => 'L0001',
    '750124057' => 'L0001',
    '750124137' => 'L0001',
    '750125108' => 'L0001',
    '750126391' => 'L0001',
    '750126570' => 'L0001',
    '750127560' => 'L0001',
    '750127927' => 'L0001',
    '750129163' => 'L0001',
    '750129771' => 'L0001',
    '750130515' => 'L0001',
    '750131350' => 'L0001',
    '750131892' => 'L0001',
    '750133009' => 'L0001',
    '850000854' => 'L0001',
    '850003513' => 'L0001',
    '850003782' => 'L0001',
    '850004107' => 'L0001',
    '850007662' => 'L0001',
    '850020616' => 'L0001',
    '850021121' => 'L0001',
    '850021300' => 'L0001',
    '850021413' => 'L0001',
    '850021446' => 'L0001',
    '850021936' => 'L0001',
    '850022554' => 'L0001',
    '850025086' => 'L0001',
    '850025604' => 'L0001',
    '850026118' => 'L0001',
    '850026632' => 'L0001',
    '850028796' => 'L0001',
    '850029588' => 'L0001',
    '850031525' => 'L0001',
    '850031869' => 'L0001',
    '850033774' => 'L0001',
    '850035853' => 'L0001',
    '850036018' => 'L0001',
    '850036975' => 'L0001',
    '850045503' => 'L0001',
    '850047648' => 'L0001',
    '850048214' => 'L0001',
    '850050236' => 'L0001',
    '850052937' => 'L0001',
    '850053362' => 'L0001',
    '850061225' => 'L0001',
    '850063323' => 'L0001',
    '850063752' => 'L0001',
    '850066680' => 'L0001',
    '850069584' => 'L0001',
    '850069678' => 'L0001',
    '850071714' => 'L0001',
    '850073275' => 'L0001',
    '850076735' => 'L0001',
    '850077758' => 'L0001',
    '850078720' => 'L0001',
    '850078984' => 'L0001',
    '850080483' => 'L0001',
    '850086437' => 'L0001',
    '850086866' => 'L0001',
    '850089431' => 'L0001',
    '850090114' => 'L0001',
    '850091858' => 'L0001',
    '850095484' => 'L0001',
    '850098492' => 'L0001',
    '850099444' => 'L0001',
    '850101014' => 'L0001',
    '850103668' => 'L0001',
    '850104055' => 'L0001',
    '850105945' => 'L0001',
    '850106869' => 'L0001',
    '850107647' => 'L0001',
    '850110169' => 'L0001',
    '850110711' => 'L0001',
    '850112135' => 'L0001',
    '850112936' => 'L0001',
    '850112969' => 'L0001',
    '850112993' => 'L0001',
    '850116967' => 'L0001',
    '850118410' => 'L0001',
    '850119546' => 'L0001',
    '850122459' => 'L0001',
    '850123393' => 'L0001',
    '850123699' => 'L0001',
    '850123930' => 'L0001',
    '850124147' => 'L0001',
    '850124364' => 'L0001',
    '850124755' => 'L0001',
    '850125104' => 'L0001',
    '850126311' => 'L0001',
    '850127904' => 'L0001',
    '850129470' => 'L0001',
    '850129578' => 'L0001',
    '850129960' => 'L0001',
    '850130695' => 'L0001',
    '850131105' => 'L0001',
    '850131699' => 'L0001',
    '850132604' => 'L0001',
    '850136517' => 'L0001',
    '850137578' => 'L0001',
    '850137818' => 'L0001',
    '850138827' => 'L0001',
    '950001015' => 'L0001',
    '950004122' => 'L0001',
    '950004881' => 'L0001',
    '950005357' => 'L0001',
    '950005381' => 'L0001',
    '950005423' => 'L0001',
    '950005729' => 'L0001',
    '950005772' => 'L0001',
    '950005852' => 'L0001',
    '950006055' => 'L0001',
    '950006286' => 'L0001',
    '950006710' => 'L0001',
    '950007219' => 'L0001',
    '950007771' => 'L0001',
    '950020155' => 'L0001',
    '950020334' => 'L0001',
    '950020739' => 'L0001',
    '950020810' => 'L0001',
    '950020881' => 'L0001',
    '950021258' => 'L0001',
    '950024021' => 'L0001',
    '950024761' => 'L0001',
    '950025138' => 'L0001',
    '950025727' => 'L0001',
    '950027118' => 'L0001',
    '950027981' => 'L0001',
    '950029532' => 'L0001',
    '950029678' => 'L0001',
    '950031870' => 'L0001',
    '950035608' => 'L0001',
    '950036028' => 'L0001',
    '950036085' => 'L0001',
    '950038126' => 'L0001',
    '950038640' => 'L0001',
    '950038965' => 'L0001',
    '950042496' => 'L0001',
    '950043293' => 'L0001',
    '950046984' => 'L0001',
    '950049101' => 'L0001',
    '950049148' => 'L0001',
    '950050769' => 'L0001',
    '950052636' => 'L0001',
    '950053386' => 'L0001',
    '950061546' => 'L0001',
    '950061744' => 'L0001',
    '950062211' => 'L0001',
    '950065073' => 'L0001',
    '950073940' => 'L0001',
    '950074614' => 'L0001',
    '950075251' => 'L0001',
    '950076156' => 'L0001',
    '950078862' => 'L0001',
    '950079748' => 'L0001',
    '950080238' => 'L0001',
    '950080342' => 'L0001',
    '950082435' => 'L0001',
    '950082699' => 'L0001',
    '950084137' => 'L0001',
    '950086565' => 'L0001',
    '950089163' => 'L0001',
    '950089493' => 'L0001',
    '950089827' => 'L0001',
    '950094942' => 'L0001',
    '950095621' => 'L0001',
    '950099572' => 'L0001',
    '950099845' => 'L0001',
    '950101118' => 'L0001',
    '950105470' => 'L0001',
    '950106672' => 'L0001',
    '950108770' => 'L0001',
    '950109430' => 'L0001',
    '950110740' => 'L0001',
    '950116930' => 'L0001',
    '950119377' => 'L0001',
    '950120913' => 'L0001',
    '950121093' => 'L0001',
    '950122827' => 'L0001',
    '950124322' => 'L0001',
    '950125171' => 'L0001',
    '950126057' => 'L0001',
    '950128202' => 'L0001',
    '950129197' => 'L0001',
    '950129376' => 'L0001',
    '950131101' => 'L0001',
    '950131351' => 'L0001',
    '950132393' => 'L0001',
    '950132520' => 'L0001',
    '950134547' => 'L0001',
    '950134806' => 'L0001',
    '950137951' => 'L0001',
    '950138960' => 'L0001',
    '960019608' => 'L0001',
    '960034138' => 'L0001',
    '960064284' => 'L0001'
  }
end

def inactive_vger_vendors
  %w[
    AP-CAS
    AP-HARR
    AGCASTRO
    CAUARTSN
    CCJIPUB
    CEDESILV
    DRTALLER
    SZWEDE
    AKUDIVG
    ALUST
    ALUTOP
    HUHESS
    ILURPS
    MAUHMEND
    MMSAPIEN
    NYUGUTEN
    NYUSOTH
    NYUSTMUS
    NYUWILSE
    SPCISN
    CCINGEO
    CHLONGPB
    CNCGPC
    CNMANRS
    COULIBUN
    COUOIL
    COUPETR
    COURECO
    COUUCOLP
    AUOAW
    AZUSIL
    BERESEAU
    GWSCHRAMM
    CAUCFC
    CAUCMIL
    CAUIEAS
    CAUPHOMET
    CAUWFVZ
    GOSTAT
    GWBELSER
    CRICAS
    CSEXCH
    CSZAKLAD
    CYMEPEP
    MDUCOLBK
    DCUGOT
    DCUIADB
    DCUINTER
    DCULIRE
    DCURECYP
    DCUWDCO
    ECCORDES
    ENKRCADE
    FLUBOOT
    FLUCRC
    ITACCSCTOR
    ITARCHI
    JANAUKA
    JAPOLAR
    HIUDEPTA
    HKDEPING
    HUNNATBA
    IECEBANK
    ILUHAP
    ILUIRWIN
    ILUJCPOR
    IRCTFSCI
    ISBANK
    ISJNUL
    NEALEPH
    NJUARTS
    NJUDAP
    NJUDT
    NJUMEMPR
    KYUINTTH
    LAUMARI
    LEPAROLE
    MAUMTHSC
    MDUMDE
    MDUWALT
    MIUMSUP
    MNUGEO
    MYRISEAP
    NYUNHHSU
    NYUPRI
    NYUREAD
    NYUSRA
    NYUUPRESS
    NZPENG
    OHUAPCO
    ONCEIC
    ONCIDRC
    ONCPER
    NJUPUBLI
    NJUVIKPE
    NVUROX
    NYUBORO
    NYUCHAP
    NYUDACAPO
    NYUFOUPR
    NYUFRONT
    NYUJIS
    TIFOTEM
    DEPALATIUM
    TNUTENNE
    TNUWTEN
    TUINSTUR
    TXULUNAR
    TXUMEMU
    ONCROYAL
    ORUUOSER
    PAUDRJTB
    PAUHISMON
    PENGUINPUT
    PKSTABAK
    SAUNISA
    SGCODESR
    SPUCM
    SPUNIOV
    SPVASCO
    SUUPM
    SWGEOSUR
    BUBAS
    JAKOBMAT
    JAKYUSHU
    JAMATHNA
    MXUNAMIM
    UMI
    UNRBENS
    UNRISD
    UNSUBS
    UWIUPR
    VAUUSIPP
    VAUVHPS
    VTUPTT
    WLKNLW
    WVMES
    CAUPROME
    COUHYDRO
    ENKAMAT
    GWGEOCEN
    NJUCDW
    NYPL
    NYUIDC
    ONCCISTI
    HARVWIDE
    IETRIN
    MDUHISTSOC
    MOULHL
    OSUHEALTH
    PAUPCUSA
    UCAUBERILS
    VAUTECH
    SWETSUK
    ILUDAVKA
    MAUNYBC
    HUSZMUZ
    NJUOLIV
    SWETBSRV
    FLUPEREZ
    AZUSTONER
    MDURWILLIA
    NYUANS
    ISRSHRAG
    CAUGETTYR
    NCUHUNTER
    CAUSCHOYER
    GWKUHN
    AGPIZARNIK
    OHUMIAUM
    DCUFAST
    AP-JBIEG
    BIBLIOPHIL
    DCUACCION
    BENNETTPEN
    NMUFILLMOR
    NMUHERING
    IOBANK
    NJUGOTT
    NJUAGAWU
    FLUCSWEP
    NJUVALPLAY
    ENKMICROW
    NJUPRINTO
    NZOCEAN
    NYUHSA
    VICI
    NYUHUDSON
    PAUSIENA
    IERENNICKS
    COUFOSSIL
    CRLIBCOSTA
    PAUWLDWC
    AP-EVER
    MAUOXFAM
    NYUAGO
    CAUFEMBKN
    PHUPHLIB
    NJUFAULK
    AP-FORMENT
    CAUGNIB
    CAUINCYTE
    BROUDE
    FRARENTHON
    ENKJGREEN
    AUDEUTICKE
    NYUMMDG
    CCACADSIN
    FRUNIVSTEN
    GAUHOOPERA
    NYAMR
    WIDERUNU
    WIURETHINK
    UKALTEA
    PHISAAA
    BAHAMAS
    INTERMOUNT
    UKDMILES
    MPLSTAFF
    UNNORCOL
    GLOBINS
    NYUBUFF
    GWBUNDEKOL
    GWULENSP
    DCULIMA
    COULANDLOC
    GWSTERN
    PAUPALEY
    OHUNECOM
    ORUMETH
    CAUHERI
    EAMB
    PAUTLAVID
    MAUUMAM
    PATUZAHN
    VAUVALEPR
    CASUN
    CCCHECQR
    NTISDOCS
    FRBIBJUS
    MNULWWIAH
    OKUCITYLIB
    PAULANCET
    MULFORD
    UWESTIND
    CTUMGUPTA
    IIBAGCHEE
    NYUSOUVENR
    AIZORYAN
    UTUINSIGHT
    BEINECKEIL
    INTERSENG
    WIUPRIMATE
    ILUPEDI
    VAUJEWISH
    CAUSWINDS
    SASARCBO
    UNIOTTAWA
    APTAAS
    ILSACTA
    ILAOCS
    CNROBERTS
    MITSLOAN
    COUNUMIS
    NYUCSHR
    KOKNSO
    CHSHENZHEN
    DKDANSKEB
    MAUMCLEAN
    ATBIBLIOZ
    MXCISS
    UKHORNIMAN
    WAUOTEVIDE
    UYJMOSES
    VTUREADEX
    VAUERIC
    BMJPUB
    CAUSANFR
    SPWTO
    GRPANEMF
    BECEPS
    PLKREINER
    MAUBAR
    CNKAHN
    GMAMAZON
    NYUPOLYTEC
    COUASES
    CAUOMNI
    UKWEC
    PEIEP
    NHUANTARC
    AGLIBARG
    AP-LIBARG
    CAUPRANAMA
    CAUARTBKS
    UKCHOLMOND
    SASALDRU
    GRPAPAD
    UKCHURCHES
    MNUHILLMUS
    CAUKAGI
    MOUELSSER
    IIMRMLBOOK
    WAULOGOS
    OHUABHLIB
    DCUCDF
    NQRAMIREZ
    GWFMP
    ITFORNI
    MIUJKKING
    JASIICA
    ENKRGREER
    GWANTIKMAK
    DCUECOLING
    UKMIKESMIT
    NYUVIDEOBE
    NYUSUBCINE
    NYUNCOONEY
    PAUTNOONE
    AUHOANZL
    GAUWHITMAN
    VAUASIS
    NENAI
    CHGTA
    VTUSTAGEP
    MDUASPB
    PLPRUSA
    NJUJDARLEY
    AP-VIENTOS
    CTUMSR
    UKLEXIS
    CAUJLEE
    NJUROSSPER
    UTUINHA
    NJUISC
    FLUFSUHIST
    POFNAC
    AUGENERALI
    ITCARTO
    CNOPALLETT
    AULOCKER
    IIAKHIL
    RURCISR
    SCUSCDAH
    MDUCDWOW
    ISRAELIFLM
    NYUHAYBARN
    SZABCBUCH
    CCSWICL
    CAUBERBANP
    TXUINSIDMX
    NYUNRLEVY
    NESWERTZ
    AP-MUTHANN
    BLARENADVD
    NYUNIIJII
    AZUAERIALS
    ITDVDIT
    LAUD
    NEWAANDERS
    DCUNTI
    DUALES
    ALAMAGERT
    CAUFIRSCOR
    IAUCAST
    DCUAACU
    BECONCAWE
    TXUCURVE
    PAUPBI
    AUBUCHSEIT
    GAUSMA
    DCUEDS
    ILUPENNWEL
    ITALFEA
    POBNP
    NYUINDIEPX
    YALEMUSLIB
    UKFARSIDE
    SWMISC
    FRSOCGEONO
    CAULASENBY
    OPSEARCH
    AP-ARZA
    AP-DARMA
    AP-OIONO
    AGVERGAR
    ATCBPT
    BERNAN
    CCHEILONG
    ENKYOUNG
    FRLLPE
    ECFLORES
    ENKREEVE
    THASIABK
    TXUMDHEA
    ABCCSPG
    ALUR
    ARUAQA
    ATCSIRO
    HKTAIYIP
    HUCARTOG
    IOYASMIN
    ISBENARZ
    MAUCHENG
    MDEKKERNEW
    MDUKITAB
    MYJABPSB
    NRMABROC
    NYULUSOBL
    NYUWASHT
    OCTOBERBK
    ONCGPC
    PORTUGAL
    POSOUSA
    RUSIBKH
    SPPONS
    CCIWEP
    CGMUTAMB
    CHCOMMON
    CLCHIP
    CNGLOBE
    COUGEODA
    CRDGESTC
    ATSJUMA
    ATUWAEXT
    AUFASS
    AZUAARSO
    BLPCS
    BLSBG
    BSBNLS
    CAUAAPGP
    CAUAIR
    CAUFCE
    CAUIPP
    CAUPCCLA
    CAUWEST
    FRISHEAS
    FRMUHISL
    GAUMRI
    GAUSCHLP
    GWGSI
    GWINSGEO
    GWINWISZ
    GWLZB
    CSMUFF
    CUBIBNAC
    CUEDIC
    CUHISCI
    DCUAAS
    DCUBIBAR
    DCUFACLIFE
    DCUFREMB
    DKAARH
    DONOSO
    ENKKOGAN
    ENKUOLAR
    FLUARTNX
    FLUMIAMI
    JAJCER
    JANSMME
    JAOSAKAECO
    JATOKYO
    JAUTORI
    KOIMH
    HUBUK
    IIRESBAN
    ILUAMPL
    ILUCONTP
    ILUSIUP
    ILUWAVE
    INUIUPU
    INUNAHUA
    ISBORHAT
    ISHEBLIT
    NHUDARTC
    NJUACLU
    NJUJANE
    LAUUPRSO
    MAUMICROSO
    MDUGUP
    MDUNATAR
    MDUNISC
    MDUPAHOSUB
    MEXNAC
    MFGPO
    MIUBELL2
    MIUCCS
    MIUSPRI
    MIUSSML
    MIUUMICP
    MOUUMCOL
    MPGEO
    NCUAARON
    NYUPHI
    NYUSECDA
    NZUOTAGO
    ONCICCS
    ONCOGS
    NJUPUNW
    NYUALGUL
    NYUARTF
    NYUBOYDELL
    NYUCENTRO
    NYUCOMPT
    NYUIAV
    SZSCHWLB
    TUDGPI
    TUJEO
    PAUAPS
    PAUCBPRE
    PAUFCPG
    PAUPHPUB
    PECEBART
    PH
    RMARSROM
    SASUSAS
    SECNSTAT
    SIHOUDEV
    SOAFSAM
    SPATLAS
    SPPAIS
    SWBFIS
    BEUBKUL
    ENKLMS
    FLUUNFLG
    GWPUMFSSP
    KOICS
    KOKYUNMJ
    PLBIBGLOW
    ARGONNE
    UKEIA
    VAUMINRE
    WAUFVHS
    WAUWSU
    WIUGENH
    YUGOSUR
    XNCUNORTE
    CAUPHOTO
    MAUHARVLIS
    MAUNORLI
    AZURI
    NEIDC
    NYUNROSS
    ONCWMAPS
    SAUDAGAR
    MAUALLOY
    NYUSLAWLIB
    UCAUBERMUS
    WAUWHITILL
    NIJ
    WIUHOCH
    WIUNOON
    ISTALSH
    ORU800.COM
    ATNEYLON
    HOBERMAN
    PAUCASTILL
    GTCIEN
    CELLARBOOK
    ESCENCONSU
    AP-BACH
    UKLAYWOOD
    SDUGEO
    MXEQUIPO
    UTUNLOGAN
    BLLAMUSIC
    PAUCARPCO
    OHUJAN
    ISACADSC
    AP-SEREC
    NYUDABRA
    FLUSCHMITT
    ACTIVIST
    CHCOMMPRES
    GWHLANZ
    OHUNGUN
    NJUBRYNMBK
    ILUARTMEDI
    ITANDS
    DCULAUGHLI
    GAUBAPTIST
    MDUAECF
    FAXONSWETS
    AMECONAS
    PAUMATTRES
    REIMAN
    WEGMAN
    ESPRISMA
    COU800AN
    NYUAJC
    MNUEASTMAP
    BOWLINGPOP
    GWGOETHE
    PUBLINTERN
    DKMUSEUMTP
    MDUFRANCEV
    AP-FRONT
    NATPARKWES
    CTURESEARC
    SWSTATCEN
    NYUTRANSIT
    TXUSIGMAB
    OHUCHADB
    FRILLEVIL
    PAUSTAGE
    CTUCATV
    NYUTBROWN
    JAIMGCOLL
    MOUMKCGEO
    TXUITRS
    HORIZPR
    AP-ARCHIVO
    SILUMED
    GWMUSICNET
    ALUTROY
    CDSOURCE
    AP-MLSC
    DCUCOSSA
    MAUHLRA
    UTENNSPLIB
    FLUHBAR
    JAJRESINST
    NJUESTRPLA
    ATCANPRINT
    COUDDS
    WAUPIERCE
    NECOEVORD
    FRAAZBOOKS
    GAUFERN
    AP-RETTA
    ONCYORICK
    NJUNINASEN
    CSCHARLESU
    NMUGROBNSN
    MDUMILTON
    SINNLB
    HARVJUDAI
    TXSWMED
    ORUCOLCHP
    CAUGJAIN
    MAUWILL
    ITORPHEUS
    NHUGOALQPC
    ONCACD
    PAUUSPOST
    IDUINSTAPE
    VAUDATATR
    ILUADA
    NYUCARY
    NYULUMINAR
    TXUUTH
    VAUIST
    GEORUNILAW
    GWBORSE
    IAUACT
    FLUJFANT
    GWUSUS
    OHUOCLCPRE
    UAEEMIRATE
    FISTATFI
    NCURAREDUK
    NPCENBSTAT
    IRINTSTDJR
    FRCHAMONAL
    MNUAGS
    OHUTOLU
    MAUHELLENI
    MDUJOHNCCP
    GAUMERCER
    STKSEERU
    NYUFIRELIG
    PEGRADE
    OHU2CO
    VAUHALALCO
    NCUBRADSHA
    NYUMID
    RURACADSCL
    NHUINTBOOK
    DIVERSINC
    BUIJORD
    CAUOSTIMUS
    UKTSO
    KYUKET
    ILUSLEEPRS
    UKIMAGO
    NYUMCURRY
    UKBASSET
    LAUMMSGOMR
    UKDANCEBKS
    UKINTLALRT
    NJUPUGLEE
    ONCEMONTY
    GWDIPLOM
    CAUUSHIST
    ONCSOUNDI
    CCTIMEZONE
    MAUMINDBR
    NYUJURIS
    COUCEAE
    MEUCORPLIB
    NEVANSTOCK
    CAUBIGFISH
    ECAMBEIRO
    CAUKOVACS
    CAUFLOWER
    NYUMUSICRM
    JAINFOMAGE
    NYUISAACS
    UKCUPRI
    UTUFAMSEA
    FLULGVEGA
    MAUFORCEDX
    ATRBANK
    EGUIA
    MOUIJS
    INMEDIA
    CENLIBANT
    ORUIADMS
    ITDEASTORE
    BRAZILFLMS
    CAUKENSTC
    NMUTURTLE
    CHOOSEBKS
    NYUPOMPRO
    NYUPALOPIC
    NYUEYSEN
    BLLIVCULT
    NYUPRESTEL
    TUISRO
    CTUACTEX
    NYUVSWPR
    COUNBJ
    SWBOKUS
    MIUFINEBKS
    NYUUSCJ
    VTUSHOP13
    CAUNEOFLIX
    AZUPGRADY
    UKHISTDIR
    NYUANNISR
    NYUSLOAN
    ATBKTOPIA
    GWSHAKER
    PROQUESCAN
    AP-ANDIN
    DCUFRAC
    MXPESCADOR
    BEMONETA
    NYUNICK
    NYUNMOCA
    SWANTIKVAR
    UKBIICL
    WAUFANTAGR
    NYUMTNVIEW
    NYUTMGY
    CAUSULLIVN
    LEDKALLEN
    NYUPACEW
    MIUBEECH
    WIUFW
    UKPRESTO
    MDUBBSMITH
    NYUEJMA
    EGMELES
    GRGREEKBKS
    NYUCDEMUS
    GWHEUBERG
    BEIPB
    CAUNEWBAY
    ILUAUDBC
    SCRIPTFLY
    UKMURRAY
    ATUNSWBKS
    INUPITSTOP
    TNUDCARDEN
    FRLAVOISIE
    NEISIM
    TNUMEDIAV
    AZULICC
    xSZITU
    TUJACKSON
    AP-VIENT
    AP-WORLD
    AP-YBP
    AGVAIZEN
    CCCNPI
    ESSERDIF
    FRAMATL
    FRLIBHEN
    GWPOLIAN
    CNEXLIVR
    ECLIBRIM
    ENKEVER
    ENKPKRBK
    SWALMQ
    TOU
    TUPERA
    TUENDER
    TUESER
    WVUPONCH
    AGSGEO
    ATANUPR
    ATCDPI
    HKHSING
    IEKENNYS
    ILUCHINA
    ILULAKE
    ILUPOWEL
    ISMASS
    ITUMBRA
    MEUAFIMP
    NEKOK
    NYUALBET
    NYUURB
    PAUKELL
    CHASIANC
    CHNSJ
    CNCSOEG
    CNDEVAD
    CNIMAN
    CNSOVEE
    CNTECH
    BCCELS
    BCCNDVIT
    BCCROWN
    BECOMBAN
    BEPEET
    BLAMDA
    BWRNATBI
    CAUNAATA
    CAURUSBA
    GRARCH
    GWABN
    GWLANDB
    GWSNG
    GWWV
    HARCOUSA
    CRIIDH
    CSSIS
    CTUHARP
    CTUKUMAR
    CUAUNA
    CUCOMEST
    DCUAARP
    DCUCFED
    DCUDOHP
    DCUEDUCOM
    DCUNFFE
    DCUPET
    DCUSINGA
    ENKSAWT
    FLUINPRE
    ITANTENO
    JAAPO
    JAISAS
    JAKURIMS
    JALIBPHY
    JATMN
    JOSTAT
    JTZEIDAN
    KOLTCB
    IEEC
    IEGEO
    IIFINAN
    ILUHUKP
    ILUUIP
    INPERADE
    INUGRADS
    INUJAREC
    IRCULT
    ISBUN
    ISGHIMES
    ISMINIS
    NERIJKS
    NERIKSUT
    NJUCOLED
    NJUGKHAL
    NJULEVY
    KYUROUT
    KYUTHOL
    LAULSLIB
    LEADAB
    LEFIHRI
    MAUCH21ST
    MAUSLIB
    MAUUNIWAY
    MAUVOUR
    MIUCJS
    MIUWSUP
    MOUCONCO
    MXBANCO
    MXINSGEO
    MXRMCAR
    MYFORES
    MYIIITC
    NCUBROAD
    NCUNCMA
    NYUPLAY
    NYUTELOS
    NYUUTP
    NYUYOMIURI
    NZRSONZE
    OKUSEPM
    NJUWOODF
    NOSTAT
    NYUABARC
    NYUAICPA
    NYUAPA
    NYUEASIA
    NYUFARSG
    NYUHAW
    NYUHWWIL
    SZORELLF
    SZWIPO
    TUILIM
    TUTIBAS
    PAUAUGUS
    PAUDCAFF
    PHDELASAL
    PHHERIT
    PLENUM
    POCOIMMU
    PPGSPN
    PPSUMMER
    PRPRPA
    RURINTEC
    SAUNSTEL
    STKCSPP
    SUMISA
    SWKVETS
    SWLUND
    SWUUKULT
    CHLIBNTU
    FIEXCSL
    HUMTA
    JAHOKKMATH
    JAMEIUNI
    WIUACADSCI
    YUSVEMAR
    UWIUILL
    UZIFEAC
    JPBEKOLO
    FRCOMMONN
    WIUALDR
    YALEUPEA
    CUAGUIAR
    XNCUVIENT
    NHUMAPTECH
    NJUFF
    NYUNWR
    TXUEARTH
    VAUCHADW
    ENKOLDBOOK
    CALTECH
    JHOPKINSLI
    OHUOHHISIL
    UIAULIB
    GRSIATRAS
    UNDILS
    ZATISA
    FAXON
    PAUPALNT
    HKIATC
    MDL
    WIILLSCHAB
    DCUNLS
    EYBP
    JORAY
    RMARSR
    VTUWGBHBO
    CTUDBROWN
    MIUTANYA
    CAUMASTER
    NYULEVART
    CHCHENG
    MMAGENDA
    NJUBNEWHSE
    ECDARWIN
    DCUKENNAN
    COUAFAPS
    AP-MICAWB
    ENKVJMOSS
    CAUVDAILEY
    WVUWISE
    AP-ROLO
    ZNLSMITSKA
    MIUTREADER
    LAUNOMA
    CAUAFR
    ECIOA
    NCUDOWNED
    NCULEVY
    DCUMATHESN
    ONCYORKU
    FRALT
    ALUOAK
    KUINFOFF
    MIUACI
    CAUCHARLIP
    KYUWARWICK
    CKBELLO
    CAUCOPYCEN
    JAURBAN
    NQANPDH
    CCCHINAINF
    NOHERMES
    DONNING
    WAUJDHOLM
    ESCEPRODE
    CAUGALLUIS
    MDULASC
    CPA2BIZ
    ILUMONTAIG
    MIUABCNEWS
    EBRARY
    SPABECCIU
    CAUACORNBK
    DEFENDWILD
    DOSVATOS
    PAUDVPS
    COUECS
    WASHORALHI
    ENKBRITLPH
    ALuUSA
    MAUCRP
    UKRIBA
    WIUNOBHILL
    PAUSHAWNEE
    NYUCRAFT
    MDUARTFR
    VAUNASDSE
    NUST
    TXUKERA
    FLUAALL
    ITBOLOGLET
    ETOU
    CAUFORMZER
    PHNSO
    LABORTRAIN
    NAVALWAR
    STKGLACIER
    BKPRESS
    JASOKAU
    USHEALTH
    PHATMANU
    PAUPHMC
    CAULIBSUR
    ATARCHITEX
    NHUUNH
    MAUBIOTECH
    NACUBO
    SWECOPOLY
    ECAS
    MDUOSSROM
    NYUPOF
    INUCSPAN
    NYUSTJOSE
    UKHULSE
    DCUCPI
    NYUSTRAND
    CAUBSR
    CAUSARTR
    STLOUU
    WAUAMAZ
    UMIGRADILL
    ITDITTA
    SZFAKSLUZ
    CALGEOSUR
    UKULEIC
    CAUEXPLOR
    SANATLIB
    CAULOYOLA
    INASP
    MAUGOTS
    ALCALA
    WASHUMED
    UKHEART
    FRBIBAVIG
    METAPRESS
    BCCECNEXT
    AMERSTES
    ENKITDG
    UNIVILLURB
    UPDATESOT
    BAREWALLS
    INFOTRIE
    NATUREPG
    ILSAMRA
    BAYWOOD
    NYU12THST
    FITINFO
    ITACCADED
    MDUAILA
    NJUA1BOOKS
    MDUNFN
    UKOXFAM
    NYUASD
    MAUFORREST
    GAUNATF
    MAUARIES
    GEORGUNI
    NYUARTPAST
    ULEIPZIG
    THOMGALE
    ORUCDBABY
    MIUPIERIAN
    AUOSCE
    PAUNASDAQ
    NYUKRAUSJR
    PLISPPAN
    TXUNAUCKS
    DKOLANDER
    ILUBEYOND
    MAUPETERS
    GWLANG
    TXUBJACOBS
    MAUACC
    MAUHYLIB
    AUUNEDAK
    UKSPOKESMN
    NYURHAPSDY
    AUCLASIMAG
    GWSTENDER
    ILUVISCOG
    NJUINDCHRT
    CYSTATS
    MIUCHAMBER
    AP-ESPINOS
    JAIDE
    VAUPBS
    MOUHOMELIF
    ISTAMUSEUM
    MAUSAHMED
    SPCALAMO
    ENKHISBOOK
    CAUVINEST
    CAUGRACSIM
    ILARPOGG
    NYUEICHLER
    NYUMERCE
    SPHISTORIA
    LAUTULBKS
    AUOSTFILM
    UKBERG
    YUSOSM
    MXJOYLAVIL
    AZUGRANT
    NRNGA
    SAARTSOUTH
    UKTROUBADR
    TXUBKSTAGE
    GWWERNER
    ABRIL
    NYUDEEPFOC
    TXUBENNYH
    UKKEOFILM
    CAUJSINGER
    ILUMSFB
    TXULONESC
    CAUTURKEY
    CAUSTREET
    OHUPAGEBKS
    PAUVERISPN
    ONCKALAMOS
    DCUMYPHFM
    GWBERGISCH
    CAUNATHAN
    UKCIBSE
    AUSHEDRUP
    NYUIES
    CAUALADDIN
    TXUWILSON
    CAUSKEPTIC
    ENKEUROMON
    FRAREZZO
    CTUMAGNA
    PAUHEYMAN
    FINALCALL
    JAMJSI
    ATBERRYBKS
    FLUWPBT
    CAUFCT
    JOCSAAR
    UKEARTHPRT
    MDUEWE
    CAUFRAMELN
    TXUOLDMAPS
    ITMONITOR
    CAUKIMOOK
    PLMUSICA
    NYUSOCEXP
    GWMERKL
    UKJIRI
    CAUSCLSSR
    FLULASER
    NYUFANLIGH
    UKTAYFR
    KSUKCBT
    OHURWEBB
    ATAAOBS
    AP-ANDRO
    FRCNDP
    UKOXBUSGP
    MDUDAEDBKS
    MOUIAAO
    MAUAISLS
    ITETA
    INUHUDSON
    CAUCREATE
    NYUISIEM
    ALEGRIA
    ENKBLETHOS
    MAUKLD
    CAUPYRCZAK
    MDUCASSIDY
    AP-LINARD
    MAUBUKHIN
    AP-BHB
    AP-EAST
    AGADOLFOBC
    BGSHAHIT
    BNA
    CAUTELEGRA
    GRVERGOS
    GWIBERO
    NCUSIMMONS
    COULMLEB
    CTUABAR
    CUCASA
    ENKINTER
    ENKQUEST
    SPPORTIC
    SWBETH
    XVAUPANAM
    AP-VAZQUEZ
    ACAD
    AGUNPCNM
    ATNSWUNE
    SPZOCONET
    HKAPOLLO
    HKNEWASIA
    ILUBAKER
    INUROSE
    KOPANMUN
    MAUMGBK
    NEDBOOK
    NESMITS
    NYUJVDDO
    NZSOPABK
    PAUSTAT
    RIUCELLAR
    CAUWPUBL
    CCUJTMET
    CHCPOST
    CHINSII
    CLLOMEDI
    CNUTLSBUS
    AZUORYX
    CANADA
    CAUKALIM
    CAULAC
    CAURLG
    GTINCEP
    GWBAW
    GWEPOCHE
    GWHUMBOL
    CTURPIZ
    CUEDACAD
    CUREVCIN
    DCUIIECO
    DCULIF
    DCUNATBU
    DCURIP
    DKNRBOG
    EGCAMOBI
    ENKCLAS
    ENKMATTHEY
    ENKREES
    ESFUNDE
    ETHCSO
    FAO
    ITISSC
    ITRIVMAT
    IVADB
    JAJIIA
    JMGEOSOC
    KOPHYS
    KORIAE
    HENRYHOLT
    HIUBRYU
    HKARTLTD
    HKCURES
    HKOLDCHH
    PAUNGS
    IDUENG
    ILUAISC
    IOBANKNE
    NDUTREAS
    NJUARCH
    NJUCAPUP
    NJUPJFA
    KSULEAGU
    KUWUHSCR
    LVRLACIS
    MAUBUTT
    MAUHMIF
    MAULINCO
    MAURMPAR
    NJUJFRIZK
    MDUCSA
    MDUCUAP
    MDUNASA
    MDUNASW
    MDUSCARE
    MIUCSSINF
    MMUMALTA
    WESTGROUP
    MSUGEOL
    MXESC
    NCUALSNA
    NCUNHC
    NCUTWR
    NYUSSRC
    NYUTHOM
    NYUVONHOLT
    OHUDNR
    OKUMUSNH
    NJUPUFSC
    NSCNATUR
    NYUCENCR
    NYUCUPSE
    NYUFIS
    NYUISAM
    NYULCHR
    SZKARG
    SZSLAT
    TEXASALCO
    TRINTOBR
    UACPSS
    ONCQUARR
    OSSREA
    PAUSLAV
    PHCBPHIL
    PLBIBGLO
    PRPENSA
    PRSAN
    RHSARDC
    SADEVBAN
    SAGEOSUR
    SASTLIB
    SCUHOREP
    SCUUNIPR
    SOCMARIMAM
    SPRABASF
    SWNATDO
    SWVETSOC
    FISOBIF
    HUNSL
    JATMJ
    NMUUNMGL
    PLIMPAN
    PLIMPLAN
    SZPROGAB
    SZUNGETR
    UNRBAN
    ALFREDILS
    UKENKBS
    UTUUNIPR
    VAUCCRESM
    VAUTEACHCO
    VEAHM
    VTUASH
    WAUCAO
    WIUSTHIS
    WIUUOWIS
    YUARCH
    RIUMEDIA
    FRMETZGER
    ENKBLDSC
    ENKMANCC
    HIUUNIV
    MAUSTONE
    MNUUMBIOLB
    NCUDUKEL
    NNCORAL
    SIRC
    UWAULIBRSS
    UWIUMADHSL
    MAUSILV
    MXFNDRCF
    WIUSBWIS
    NYUFIRST
    COUTIMELY
    HKCOSTUME
    NJULANSKY
    ESSALVA
    ENKDALIAN
    ENKOLDBK
    SPACADHIST
    NYUNYFILVI
    JEWISHMUS
    CAUUCMUS
    TUATATURK
    ENKOULWAR
    NYUKWIL
    IIMARTIN
    CTUOPUS
    NYUIBES
    AGLITORAL
    PSYCHCORP
    UKIFLA
    RIUJCBL
    NYUDOITT
    HIUBAMBOO
    PAUATHEN
    CHARTIST
    VAUNSSGA
    ENKAFBKCEN
    NYULATP
    SCUTAYLOR
    FRVEYSSIER
    NIINVERS
    MNUHILLMON
    VAUBRILL
    UKMAPSWW
    GWSAUR
    AZUOPENCOM
    NYUIFCO
    NZLEGDIR
    COUAAFS
    GEDSI
    PAUFRANKBC
    GAURUSLIB
    NYUACTFL
    FRLHERAULT
    CRCCPUCR
    TXUTRSDLIB
    TUSOSYAL
    CAULCSC
    DCUGEODAHL
    STBUXTON
    CAUZCLA
    MDUHISPAM
    VTUCBSVID
    UNPOPFUND
    NJUVICIM
    CTUKARGER
    TXUOCEAND
    NMUALAMOS
    ATAIHW
    FIGLOBAL
    IECHESTER
    IERESEARCH
    NJUGRINPRT
    MXFELGUERE
    UNITIB
    VANCCOOK
    MTUDARCY
    CTUGRAPHIC
    NYUROCKFND
    FRALAPAGE
    TXUOTC
    CAUOPENEYE
    OHUCLEVE
    OHUCINCIN
    PAULEXBAP
    NJUSTARLED
    UKUACES
    CNOTTAWA
    CAUHIGHWIR
    ENKUNLOLB
    OKUBAPTIST
    BAHSLUO
    UKSLOWELL
    NYUPRAXESS
    PAUBETH
    NEUUMEDGO
    UWESTINDBA
    VAUWILLBEL
    TXUHEALTH
    FLUDRAGON
    FRBMEPINAL
    PAULWW
    CAUFDORREL
    WIUMCW
    UKMARKHAM
    PROUSSI
    NYUCCBROWN
    ILSAMHEALT
    ILSSPIE
    ILSSTORM
    ILSUNIHANN
    ILSUNIBRIS
    CAUBANKSJO
    UKMGREGORY
    MNUBKHOUSE
    SPRINGFLD
    NEMEVIUS
    CAUCAPO
    UKTHEZONE
    XAP-LEXICO
    AP-HOGAR
    IAUPERFECT
    INUKRESGE
    NYUARTSTOR
    UCLALIB
    ISFELD
    IEUCC
    CNTRAFFORD
    AGSGMAIGRM
    WAUAFD
    PLLEXICON
    PAUYEA
    CHCDB
    CAUTAVIS
    ATNSWGOVBK
    NYUCHINAIN
    BEINTERSEN
    HKDSSCSD
    NE010PUB
    SZLHSNUM
    DKBOGVID
    ONCAGO
    UKFULGUR
    INUAPPE
    CAUMENEMSH
    CHICAGOFI
    MAUROBKING
    FRITSKNUF
    NCUMCGOWAN
    IIORGCC
    MAUBUYINDI
    FLUTROPIFL
    KYUDISCVRY
    ISBKGALLRY
    NYUNEALSCH
    EWORLD
    CAULEFTCP
    BLIBGE
    NJULAWRSCH
    NJULPENDSE
    TUFTSUART
    COUTHOMREU
    ILUKARTEM
    MAUFOCUS
    MAUZEN
    BELANNOO
    FRPOMPIDOU
    FRLIVRES
    BLSUBMARIN
    NCUFINEBKS
    LIRHUMANIT
    UKPENDBKS
    CNCIUS
    UTUASP
    CTUTAM
    UKENVIRFIN
    DCUUSCC
    OKUKICKING
    SPABSOL
    ENKDESIGN
    CHTBMC
    QUCRENAUD
    DCUCGS
    ITBOLITAL
    MOUPHOENIX
    NYUHARTWCK
    NYUSANCTU
    JAGJPHOTO
    AP-BARLO
    NYUMATA
    CANKOREA
    CAUOUTEQU
    FREDSOLESM
    CNFERGUSON
    PAULINNEMN
    TNUKILOURS
    FRLIBKNUF
    YUARTBEL
    NYUINFOPUB
    UKCREEL
    NYUESOPUS
    NJUJOSMITH
    CAUPEWBURN
    CAUCHINABK
    MDUGSTRUM
    CTUSCHOLAS
    NYUSRLP
    COUBOONE
    TXUDEUPREE
    ITBERGOGLI
    NJUMCCARR
    PAUPITTS
    BLVIDFORUM
    OHUHOFF
    PAUPAFA
    NMUPAGEONE
    NERUG
    ENKBLACK
    LISTATS
    NJUJMOFFA
    AGCEDINCI
    PAUHIBD
    NZOTAGO
    CCASMSS
    DCUCBGOV
    DEULYNCH
    GWFILMMUS
    KARDAMITSA
    NYUSIEBENS
    CAUKETAB
    RIUSHERPA
    KOPANEKS
    AP-BNA
    AP-ISIS
    BCCRAINBKS
    CAUBOOK
    CCHUNAN
    FRLAFFI
    FRLIBINPHO
    GAYCOMMNEW
    GEZENT
    GUTTAG
    CLLIBROS
    NYUVOXGOV
    ENKSHIP
    UYRODVIL
    VECOLLIB
    ALUGEO
    ATNGV
    HKSUNBC
    KALMAN
    ZKAMKIN
    MAUJHALL
    MXPUVILL
    MYPARRY
    NYUASAHIYA
    NYUBAKER
    NYUSUAREZ
    ORUMORR
    SHISHKIN
    CCTPC
    CEICES
    CHSCIENC
    CLESECON
    ATPACLIN
    AUDOKU
    BESOCROY
    GRAVERGOS
    BWHITE
    CAUCEFRO
    CAUDIACO
    CAUDOSIJ
    CAUFINAN
    CAUIATTC
    CAUMAZDA
    CAUMONIT
    CAUNOGH
    CAUSAAAI
    CAUTHE
    CAUUCSBD
    FRBRGM
    FRCCPLNR
    FRCHAMP
    FRIGCP
    GAUATLRV
    GAZDEF
    GTINSTNT
    GWBUNDE
    GWKLOST
    GWPREUSS
    CREDUNCR
    CTUSEARS
    CUCENFEL
    CUISRIRG
    CUUNIHAB
    DCUARC
    DCUASNE
    DCUCSIS
    DCUNAPA
    DCURESOU
    DKDKDVS
    ENKULBLE
    ENKWINDR
    ENKWPCST
    ESFINANC
    FFONSECA
    FLUIDEAL
    ISTAUMUS
    ISWIS
    ITIDROBI
    JACHOSIN
    JARADIO
    JOACOR
    KOPDSC
    HKHKUPR
    HKREADER
    HUINST
    HUPEST
    IAUIGS
    ICICE
    IEIRISHB
    IEORDNAN
    IINDIAN
    ILUBOLCH
    ILULOG
    ILUOUP
    IOUNDINS
    ISIPRG
    ISJRAMD
    ISMDPH
    NEKIT
    NGCOLPRE
    NJUBRYN
    NJUCIS
    KSULAS
    MAMANEH
    MAUACE
    MAUBLSCI
    MAUBOSAU
    MAUHUGSD
    MAUKLUW
    MDUBUMIN
    MDUCLEAR
    MDUNIP
    MDUUPA
    MOUNEWL
    MOUTWAIN
    MOUUMP
    MXDEREC
    NYUODWY
    NYURIG
    NYUWOMIN
    NZSTAT
    OHUPRES
    OKUAAPG
    ONCCIHM
    ONCESNOW
    NJURUP
    NJUTRANS
    NMUSARP
    NONORGES
    NRGEOS
    NYUARCE
    NYUAUTON
    NYUDATAS
    NYUGEN
    NYUGREEK
    SYMARIFA
    SZLANG
    TIINS
    TNUSTATE
    TUDEISEN
    TXUDFD
    TXUTXA&M
    ONCPIMS
    PAUCOWLS
    PAUHISAS
    PAUNEW
    PHADB
    PLBIBNAR
    PPINSTIT
    RUINION
    SAILAM
    SASKEM
    SAUMM
    SIAMIC
    SISTAT
    SPAZNAR
    SWOSTMU
    SWUSGEO
    BUBAN
    CHPUL
    CLIIG
    CSSVK
    ENKASHMO
    GWMIALUF
    ITUCBIB
    JARASS
    NESUUMAT
    RMBCS
    VEACF
    UGUNDACB
    UKLLP
    UNEVLVARCH
    UTUBEBR
    VAUCONTIN
    VIUNVIS
    WAUTECHN
    BLMCCART
    CLBERENG
    GLOBALENGD
    ATUQSL
    ONCFEDMAP
    UKAHOOK
    CAULALIB
    HARVUFALB
    MTUHISTSOC
    WASHULAW
    MXSBM
    ATSOUAUS
    HKTEXT
    GAUNEW
    UKJDRURY
    NEGBEST
    BALLSTATE
    VIRTUALJUD
    NJUHIDDEN
    NACLA
    AGAMUJICA
    ENKLOWEND
    NYUASE
    FRPICARD
    MYMMS
    SZIDMATH
    NMUEDITION
    TUCENSTRES
    CLINLIBER
    NRNISER
    TXUCOMPTRO
    UKTEBLTD
    NYULFOX
    FRLEBAILWE
    CNDHAYES
    FRLIBRI
    MEUCILS
    ECOUTTS
    DCUWBPUB
    CTUAWB
    CAULEVENS
    ENKJTAYLOR
    PELCAMPO
    NLCCEDMED
    COUTTSNIJ
    UKARTS
    NJUBARTON
    AP-PROANO
    PAULEXISMB
    AP-RUIZ
    BDINSTAT
    UKFINEART
    VAUCHDARW
    FINLSF
    NYUTFER
    FRFATON
    COLEGIOMEX
    FRSOMME
    KYUJCFL
    CAUSDAG
    NYUTRCO
    HKUHKILL
    INTMARITIM
    NYUSTJOHN
    TNUCLIENT
    AZUOLDWORL
    CAUACPRESS
    UKAAPUBS
    SWLUNDIT
    COUDCM
    MAUMITPER
    SAVGALLERY
    MDUIIE
    NJUFIAT
    NJUFRESHA
    AP-VEGA
    VAUWHARTON
    NHUCORNISH
    NATGEOMAP
    INUJOHNLIB
    UNIBRAUN
    NYUDEMNOW
    ATMIA
    NYUBNTM
    PAUSCOTT
    NYUUNIONL
    VACADMUS
    UKMETAPRES
    WORLDBANK
    KYUNORTON
    PAUSLOUGHT
    DVDBRAZIL
    FLUMED
    WIUJCUMM
    MDUQUAX
    NCUVHH
    PAUPSMS
    GALWAT
    GWADVANCE
    GWIWF
    WESTRESV
    GASTECH
    NJUATY
    USANDIEGO
    FRCHEMINS
    ILUWCC
    ILSMIT
    LANDBIO
    CAUPACSEPM
    NYUNYSMU
    ILUAFSA
    NYUBCA
    FLUMMP
    NYULIBSHOP
    NJUCORFACT
    CAUSOUNDS
    ENKSENATE
    DCUJIES
    NEIBFD
    MCGILLISL
    DEMACON
    INUNDLIB
    FRINHA
    DCUTNR
    JAHINOKI
    UKCOUNTRYW
    YUKNJIZARA
    INUPDKEDU
    ILSIRG
    EMBGREECE
    SZARTFILM
    NYULOVELY
    CAULILYFLM
    NYULONGBOW
    KOPANAC
    UKCLARKSON
    AP-LEXMAC
    SZLELIVRE
    ISYBZ
    TXULACIMA
    ATPUBART
    UKWNA
    NYUPRATT
    GRHESTIAS
    CAUGOLDFLM
    NZSOUNZ
    CAUCALGIRL
    NYUNYIHA
    CCZHONGGUO
    ATMUP
    WAUCONNEX
    NZJOCKHOE
    ATRILEYLEE
    CTUPBARON
    CAUSCIARC
    ITLIBROCO
    MAUMIMAR
    FLUALLENSO
    HIUBKLINES
    ITISTAT
    NYUROUSES
    CAUEERI
    SFSTAT
    ISRAELCAT
    UKWMPOOLE
    GWKARAJAHN
    CAULEIBER
    ITSIF
    APTA
    EKOZMENKO
    MAUSENECA
    CAUROCO
    UKMUSICRM
    MAUJRPITA
    GWGFKGEO
    JAJETRO
    SZIOM
    UKNPG
    MAUHARVDB
    CAUAFF
    NYUVALLEY
    NYUPS1
    CAUSUM
    CSNLCR
    COUVETHOPE
    UKBFI
    FLUTAMPRES
    AP-ALININO
    NYUPCHANG
    NYUBROOKMU
    AGCONTRA
    AP-KOZMENK
    AP-COUTTS
    AP-THORO
    ZUBAL
    CAUCHIN
    CAULIVAF
    ENKWILS
    FRALIX
    FRCOURANT
    CTUELLIOZ
    CUESTA
    ENKCLIVE
    TNURAMAL
    AGINSPI
    HKCHINANEW
    CNARTMETRO
    HKMAN
    IIVEDAMS
    ISLUDWIG
    KNKPUB
    KOKORPUB
    MAUTGBOS
    MMBOOKS
    MXPARED
    MYINTBOO
    NCUAZTEC
    NEINTGEN
    NJUARCAN
    NJUROBIN
    NYUPHILL
    SPLIBROD
    CHCHIPET
    CHCONT
    CNINFOGL
    CNLAVAL
    CNSLSA
    COUBKBUF
    COURIEN
    COUSEG
    COUUCRC
    BERNDEP
    CAUDIBBL
    CAUFIRST
    CAUPYRAM
    CAUSLIB
    CAUSTC
    FRCODATA
    FRICA
    GALE1
    GIS
    GWSTADHA
    CRINCAE
    CTULOG
    CUEDIPUE
    DCUAISI
    DCUAMASM
    DCUAMTRA
    DCUPALCEN
    DCUGHI
    DCUNASDA
    DCUNAT
    DKNORDIC
    DKSTAT
    ENKBAS
    ENKRIIA
    ENKSMI
    ENKSRS
    NYUFACTS
    FLULMRL
    JAJFEA
    JAKUENG
    JATAO
    JAWAS
    HUELTE
    ILUANS
    ILUISL
    ILUMACMIL
    ILUUCPR
    IOASEAN
    NHUAYER
    NJUBEHR
    NJUBELLA
    NJUBNA
    NJUDRBC
    NJUMSM
    LAULSU
    LAUPNO
    MAUEAST
    MAUPWS
    MDUASOR
    MDUASPIN
    MDUASPPU
    MDUDOP
    MDUILO
    MDUMARYH
    CHEN
    MIUHARMON
    MIUISR
    MIUUMSLA
    MOUMBSTEXT
    MWGPRDZ
    MXBANAMX
    MXUASLP
    NEUSTNB
    NEUUPRE
    NYUMORG
    NYUSTMAR
    NYUWALK
    OHUCMOA
    ONCMOF
    NJUTRENT
    NJUWATS
    NMUUNPR
    NYUISLAM
    SZHLANG
    TEKIN
    TNUINSSM
    TUUNION
    TXULANDES
    ORUISBSI
    ORUPUBLI
    PAUAUGSB
    PAUBIS
    PAUREDHO
    KYUTAY
    PAUTUP
    PAUUMUS
    PLSOCAM
    PLWROC
    QUCICAO
    RIUBOE
    SACHAMSA
    SFSSP
    SGBUD
    SNCSTRUC
    SPFUNHT
    SPRACEFN
    STUNYUALB
    SUCOOPCO
    SUMFNE
    SWASTROM
    SWGOTUNI
    AUUWIEN
    ITBUM
    MIUUMLIB
    MNUMGSEX
    MVRBAN
    RMTIMEX
    SZNEUCH
    ZUKCHICHE
    FROGN
    VTUWGBH
    WAUTRIB
    WIUCENTE
    YUMEDPOL
    AGROSSI
    GAUCENSUS
    ILUUCHILSC
    MZALCANCE
    MBCWUERZ
    CAS-DDS
    CAUINFOTR
    HARVWIDEIL
    NYUBECPL
    ONCNRCOC
    UMDULAWLIB
    VAULIBVA
    BHBL
    BLKSER-GB
    SWETSUS
    AGRFRAGA
    UKTHORNTON
    KOYEUNGNAM
    SUKISAARCH
    FLUVOODOO
    GWRFMEYER
    JAZZSTORE
    SIOXFORD
    NYUCUL
    NZGEOSERV
    NYUTHINAIR
    IELING
    ONCMOCCR
    ENKLORDS
    NJUPUSTU
    FRAURORAB
    NYUA&ETN
    PATELSONS
    GTFUNDESA
    ENKETON
    NYUJKENT
    SCHUBERTAR
    CAUEDA
    BCCRUWEDEL
    WAUKIESEL
    ATBUYWELL
    GWKOCH
    VTUNHARMNY
    GAU5MINS
    NYULEXIS
    ORUPTB
    PUBLICPOL
    CTUEUROPA
    WEWORLD
    NYUACHILD
    MDUWOMNSLP
    KESURVEY
    EEVER
    NESCHUHMAC
    ETCOMDIV
    ILUSAA
    MDUBOOKSOD
    JGPRESS
    CTUROUT
    MAUJFKLIB
    MAUNCJF
    ENKDAIWA
    JANIKKEI
    AP-MEJIA
    AP-ATA
    DONALDLAND
    NCSTATEHIS
    SRICENSTAT
    SISELECT
    ENKAHUNTER
    FLUTHINKB
    NYUCUPRESS
    SPCINDOC
    HIUMEDLIB
    UKWHSMITH
    FRGIRONDE
    ORUSAPULI
    TXUHSC
    KSUSTRICT
    VTUOTTAUQ
    ITBIBBER
    PAUDVRPC
    SPCASAMAPA
    SOCEX
    MDUNIST
    BARCELONA
    TXUMARINE
    NYUSTACKS
    NYUZOGBY
    CIVICRESIN
    FRBMCAEN
    THPROFBK
    CAUCYCLING
    COULWAIT
    UKWILEY
    MOUECOTONE
    PEPERUBOOK
    MCGILLLAW
    UKBECKHAM
    UKCER
    MNUFATTVID
    ENKBRILL
    IIPRATAP
    MTUMGS
    TXUFULJAW
    AP-ATLANT
    AP-ESTEVA
    CTUCDU
    MDUAPHYSIO
    UKBRE
    AP-BERENG
    NYUGREYHSE
    CASEWEST
    NEGL5PCB
    MIUUMLIBOF
    ECUASB
    CNVANPUB
    NYUCOLUDIA
    GWHAMBURG
    NYUWRKSHK
    MDUFROST
    FUTRDRUGS
    SCIENCECH
    BIBCENTRAL
    AMERMUSIC
    FLUSAND
    NEMILLPRES
    JRHEUM
    AP-MARSILL
    ILUUREGEN
    ECSSR
    KSUACG
    GRKEPE
    FRESCLILLE
    CAUGOC
    IIPOPPRAK
    MAUTUFTSIL
    COUMGMA
    GWAICA
    CAUGREEKSH
    SZLEUNUM
    IMPA
    CAUKAISER
    MAUPRECIS
    NJUSIMCHA
    DCUAACC
    CAHERON
    UKPALGRAVE
    MOUGARDEN
    CAUMOVIE
    CAUMSPHILL
    UNOSAA
    NJUMONARC
    DCUNACDL
    GWWVMBERG
    SPMPADURA
    CCBEIMAN
    DCUMPI
    CNWEBSTERS
    DCUINTERSK
    NCUVIENTOS
    CAUBONHAMS
    VTUERTUG
    KYUITBUSED
    FRFNAC
    GRCRETA
    OCLCASIA
    SJABBAR
    ATMSTLEON
    NJUNJAPA
    JATOKYOGAL
    NEBURGNIER
    BLDEP
    TNUUNMEPH
    MDUISLAMIC
    NERMIBGEO
    DCUAERA
    UKWLUML
    CTUTURPIN
    ILUSINFCAM
    NEVSTATELI
    OHULTC
    TXUMEDIAPR
    YUSTATSERB
    NEUNHA
    ENKINFORMA
    ITTOPTEN
    CAUIMAGEX
    LITRIOCHT
    NJURUDLSER
    BEJOYROYCE
    VANDENGRAV
    CAUKVISION
    NYUCWLP
    MOUSBAKER
    SYATASSI
    AP-KARNO
    MENDIOLA
    DCULHF
    DESHANTORI
    MOUIRE
    NYUGERI
    ITLIBRAWEB
    VAUUPF
    UKSPECBKS
    ISIDIP
    MNUHYRDOSP
    AMJOURJUR
    CAUDUIHUA
    WAUCCOHEN
    AP-COBO
    NEKNAW
    NYUNYSBA
    OSCILLO
    NHUSOLPRO
    CCBEIJRARE
    UKKINGS
    GWBUCHER
    UNHABITAT
    NYUSNOWLI
    PAUSCHIFF
    TXUHAMON
    NYUFIERRO
    NJURARWS
    MDUNATF
    NEFMELK
    CCFRELAX
    WIUMADCSA
    SWERATO
    DCUPEACEX
    GWOLGAFILM
    FRMK2
    NBCUSTORE
    UKUMP
    NJUGANJ
    USTURA
    NYUMAGUR
    MIUUMPALE
    UKBRIDGE
    IRANIBOOK
    DCUSAA
    WIUPARALPR
    MXSPITOL
    ITFENICE
    FLUJESUS
    NJUVERA
    FRARCHIPEL
    UKHYPEREC
    SIMARCAV
    BYUFIELD
    AP-ERASNE
    AP-IBEX
    AP-JERU
    AP-LEILA
    AP-SHAM
    AP-SZWED
    AP-TOU
    NYUPSC
    ABCUKRBK
    ENKWATST
    CHCHIAY
    ENKADAB
    ENKBREMAN
    VELIBHIS
    AGALAF
    AGUBA
    ALULEGO
    IIPRI
    ISJEBAR
    MACH
    MIUCZEK
    NYUKRAUS
    NYULISUR
    NZNZEX
    ONCCBBAG
    PAUCROWN
    PAUMJOH
    QUCDIFF
    SIGUOJIT
    SPLASTUD
    CHGEOSOC
    CLCIPMA
    CLFLACSO
    CNNSC
    COUSHEP
    CRBCCR
    AZUGRAND
    BDBANRB
    BEMAEDGE
    BTSTATDI
    CAUBERBANC
    CAUBGIL
    CAUESRI
    CAUIAP
    CAUIISUC
    CAUSMALL
    CAUSPACE
    CAUSTANL
    CAUUABC
    FRDEBOCC
    FRMETZ
    GAUADOF
    GWINTRES
    GWMSK
    GWOTTO
    GWPEYKAR
    CSUNKOME
    CTUGREEN
    CUICAP
    DCUBROOK
    DCUCATO
    DCUDEFEN
    DCUFEDSY
    DEUSCHOL
    DKGEOMUS
    ECBANCO
    ENKCPS
    ENKINPEN
    ENKSOAS
    FLUCHAP
    FLUCRE
    FLUSOUTH
    FRALCA
    ITERBRET
    ITUNIVV
    IVUNCI
    JAHUDGM
    JAPEPT
    JASHIZSC
    JASOPHIA
    KEEANHIS
    KEGOVTPR
    KOARTHS
    KOROYAL
    HKCEN
    HKGOVP
    HUHUNECO
    ILUCBT
    ILUFIBRE
    ILUILLCO
    INTNUTFOU
    INUMONG
    IOIAIN
    NETLIN
    NJUESSTA
    NJUHUMA
    MIUREVDIG
    KYUDIR
    MAUKLAW
    MAUPAUL
    MDUAIA
    MDUCISI
    MIUROMAN
    MWDEVCOR
    NATAUDUSOC
    NCUGEOSU
    NYUNYRB
    NYUORBIS
    NYUQUE
    NYUSOCOM
    NYUSOUTH
    NYUSWEET
    NYUUKR
    NZDSIRGE
    OHUAIOA
    OHUCLEVPPH
    NJUSLMUN
    NJUSOCIR
    NMUGEOSU
    NYUABRAMS
    NYUCAAA
    NYUCATA
    UKFOLIO
    NYUFORTI
    NYUFREEM
    NYUGUILF
    NYUIII
    NYULATIN
    NYULAW
    SYAPR
    TUDEVLET
    TXUWELCH
    ONCWORLD
    PAUBIRD
    PAUEDU
    DOURGARIAN
    PAUHERAL
    PAUINSCI
    PEDESCO
    PKCHEM
    PRPOSTDA
    QUCFORCE
    SAINSTIA
    SASUCT
    SAUNIVCA
    SISINGUP
    SPACCSOC
    SPINSEGI
    STKSCBK
    STKEMS
    SWNORDIS
    BUEXSEC
    CCISTIC
    CSPURK
    CUACCGE
    HUZENET
    JAKUCE
    MSUSIE
    NDUEXCH
    UCAULOSLI
    UKKHUKH
    UTUFOU
    UTUHIST
    UVAUPRINT
    VAUASCD
    VAUASPEC
    VAUCWM
    VAUMICH
    VCBAV
    VTUMULME
    WAUDNR
    WAUQNRED
    WAUSEATL
    YALEUBEINE
    ENKBRITL
    GWBAR
    HKGEOCAR
    MEUDMC
    NJUOCKER
    NJUSCORP
    NYUMUSIR
    ONCVERGE
    VAUPBSV
    ATNLA
    CTUYALEL
    NYUBOTLIB
    GWROSSICA
    STKNATLIB
    UMOKC
    ISGEFEN
    KUBONSER
    AEBN
    ATBSL
    MAUNATION
    OHUACS
    ZINCA
    CHCNSM
    TSAIFONG
    NYUFILM
    ILOPUB
    EALIBRIS
    MDUFDCH
    CNSGC
    JPISL
    ATANDER
    PEARSON
    CAUSCHWARZ
    FLUSEMINOL
    AP-ERASFR
    SCUUSCGSC
    FRCESMAN
    NJUDIVLAW
    CHRANTICOM
    COUROAD
    PAUCGENS
    EBNA
    EBHB
    ENKJHS
    NYUBEIJ
    CAURAREMAP
    GRVALAOR
    CAUGLOBEX
    VAURAINMAK
    CYIPS
    EERASNE
    EERASFR
    NYUPARISH
    NJUSTIEFEL
    MAULAMEDUK
    GPCOURSE
    KUCRSK
    INTSTIN
    CAUPBA
    MAUDSTEKOL
    GOSSELS
    BOSILES
    SZICJ
    NYUHOURGL
    UKHORIZON
    XMAUEBSCOP
    ISHAIFAU
    ILUGARRETT
    UKGLOBAL
    NYUFARRAR
    MXGAVITO
    HIUSTLIB
    NYUYEDIOTH
    PAUBAUMAN
    ENKTRIBOOK
    CNEMSQD
    GWSTOCKHAU
    SCNWHO
    FRINSEE
    NYUWHITMUS
    UKSTAGEDIR
    NYUQSMG
    PEARSPER
    CAUBERKCNR
    NYUKOVALSK
    CAUGRIS
    DCUENDSPEC
    INUBLKFLM
    MDUNASACAS
    NEKLOOF
    CKARCHIVO
    UMSROWLIB
    UKBHOLDSW
    CAUOMP
    REAYUMCOL
    POINE
    CTUHART
    CAUDCW
    UKBBRANDT
    DCUFOLGERL
    REUSE
    PAUMEE
    CAUBASRC
    NELICHBLAD
    SZISO
    HARVARDILL
    ATMCMILLAN
    CAUUCSANFR
    CAUBERBAN
    TNURALLEN
    NYUCVR
    ILUEDRES
    SHEETMUSIC
    PAUUNIVPAL
    GWNEUMANN
    PAUSUSL
    UMINNLIB
    INGENTA-UK
    HELLENIC
    WELCOMTRUS
    KSUMED
    MOUUMKC
    UKORSURVEY
    EUCLID
    MTUMPL
    IHSINC
    BNAILS
    ISHS
    UKINASP
    AMSOCAGR
    MAUHARVPHL
    VAUADST
    MAUGENE
    QUCLAVAL
    HECKMAN
    ITAMBROS
    SIRCINFO
    INASDENRE
    ILSMASSMED
    TXUMEDINST
    GWKEIP
    NZNATLIB
    FLUMAIMIDA
    DCUBEA
    UKCBP
    UKJABBER
    NEISS
    DCUEWC
    CNNORSTAR
    ORUIRVMUS
    NYULIONESS
    DCUYORKZIM
    MAUAJAMI
    UKAFRICANA
    GWLIBRI
    PAUCMOAS
    EBNAINPROC
    NHUAGI
    AGMAGNASCO
    NJUSCHOLAR
    JMRANDLE
    NRNES
    JAYAMA
    NYUNBPC
    PAULONGWOO
    CAUFJP
    AP-MOSS
    AP-IBERO
    CLLEGANOSU
    DOMACAK
    NYUTARDOS
    SPJRULFO
    VAUOHS
    STKEUL
    PAUROBINAR
    UKHELLENIC
    CAUHANBKS
    ORUCLEAR
    GWGVS
    UKLOSTBKS
    MDUIVIOLIN
    IHSGLOBAL
    iriranfarh
    IDUWATSON
    WIUMILCLAC
    VAUFALWELL
    CAUWOLFE
    NYUFLLAC
    PAUTFJOUR
    UAAUCBKS
    FRSWANN
    KOKIHSA
    VAUC2ER
    MIUUMSPO
    NYUSDCF
    UOFMICHBUS
    FRALSPRANC
    AZUJKOVAD
    NYUPRIMRG
    AGMAGALL
    MDUARL
    MDUFARREN
    UKEUROSPAN
    DCUMBA
    CLHOZVEN
    NYUORNITH
    NJUICAP
    UKLATINMS
    PAUJUDSON
    HKFORMASIA
    TNU3DAUDIO
    NYUTREVIAN
    NJURUCGS
    CTUFILMIC
    MEUCARLSON
    GRBENAKI
    DCUACSUS
    NJUASTAHL
    UKTRL
    ATMILLHOUS
    AP-ARKIVMU
    UKGREENLF
    VAUNASBE
    FIKARTTAKE
    EEAST
    ASPS
    IIIFAPUB
    NYUWWB
    NYULINEAS
    GRNML
    NYULILDUST
    NJUFII
    CCCHCHEM
    ONCCBC
    NELEIDENUP
    CAUCRP
    CAUINDPR
    MAUASPECT
    CAUNOTOW
    UMICHPRPER
    CAUBONANZA
    ONCCIGI
    GWCINETIX
    KSUBKMARK
    GWJPC
    NYUROSEN
    ARTEXDC
    AP-DEREX
    AP-AFBKS
    AP-DAFT
    XAP-NORTE
    AP-ORBIS
    AP-SUL
    ACBK
    ARUROUN
    AZUDFDOC
    BBMOSS
    FRCLAV
    ENKORB
    ENKROTA
    ENKTANG
    UKJOPPA
    UKQUEST
    ZVEVENBK
    ABLEX
    AGASOGA
    ATAUSG
    ATAUSMUS
    GWWASMUTH
    HERRERA
    MAUBERN
    MDUJAHAN
    NRJINT
    NYUCSBE
    NYUHACK
    ONCIRC
    PASSIM
    PAUBENJA
    PKUNIVBK
    SIMPHBKS
    CBINSTCP
    CCCSSMR
    CHNCL
    CICRPHYS
    CKDANE
    CMBADEAC
    CNGSC
    CNINDIAN
    CNUBCPR
    CNUTRANS
    CRCAPEL
    ATSAMINE
    AUDOBL
    BGBIDS
    BLSEMUCU
    BPSTATIS
    BXDEPD
    CAUACPR
    CAUCCEB
    CAUCHRON
    CAUCIPA
    CAUIASB
    CAUINTJU
    CAUJOSSE
    CAUPASTO
    CAUSOCL
    CAUUCMEX
    FRORSTOM
    GLPINT
    GUOVS
    GWSCHROD
    CRFLAC
    CUCDR
    CYROCDOS
    DCUAGU
    DCUAOU
    DCUAPTA
    DCUCSBA
    DCUINFNR
    DCUJCPS
    DCUNFUCW
    ECCIDAP
    ECCIUDAD
    ECCORDAN
    ENKVOLF
    FIUBF
    FLUCANF
    FLUGEO
    FLUIBD
    ITUNIVM
    JADIET
    JAINSMT
    JAMTHAKK
    JAPNIG
    KAUUMASA
    HIULTGOV
    HIUTAX
    HIUUNIPR
    HKCELEB
    IDUMNH
    ILUCBMR
    ILUGEOSU
    ILUONEON
    INUIUP
    IRIPBIS
    ISIBRT
    NEGEO
    CUBANCODEM
    NJULABOR
    NJUOPR
    LIRBAN
    LYLSTC
    MAUCOMPL
    MAUIPG
    MAUJONES
    MAULITT
    MAUPROSL
    CAUAPPLE
    MCKEE
    MDUBAG
    MESTLIB
    MIUPOSTI
    MOUCRR
    MRGEO
    MXINEGI
    MYRASM
    NYUMATT
    NYUNATUSC
    MIUARC
    NYUTRNTL
    OHUIAEE
    OHUIJP
    ONCNATAR
    ONCNHW
    NJUPTORY
    NJUPUBAF
    NJUWILSON
    NMUDFC
    NOPOLAR
    NVUGEO
    NYUACM
    NYUAMNES
    NYUAPS
    NYUBISER
    NYUCCNY
    NYUDEKKR
    NYUDESCA
    NYUELS
    NYUEMF
    NYUFPA
    NYUGROVE
    SZISSA
    TIASETI
    TUILET
    TUTARIH
    ORUOSU
    ALUBIRDS
    PAUELMP
    PAULIPPI
    PAUPSUEM
    PEBCRDP
    PHUSC
    PKHDC
    PLARW
    PNBANCO
    SALALM
    SCUSCARO
    SPMMOL
    SPPUBBAR
    SRILANAT
    SWTLME
    CAULIBEX
    FRUBESAN
    PLBIBGDA
    SUKABDUL
    UKYUYOUNG
    USGPO1
    VAUASM
    VAUJANES
    VAUSMINP
    VAUUPVA
    VEINTER
    USGPO
    ILUCOLL
    ILUFACET
    MAUBERKS
    NYUCOMP
    ATANUL
    ATUQLDLIB
    INUULIB
    MAUHARVCOL
    ONCMICRO
    STUNYSBILL
    UMAULIB
    USCAULIB
    CAUMAP
    NJUSAI
    ENKHBARON
    AVENZA
    RUSHAMB
    FLUFIULACC
    GTLIBMILL
    PRINCP
    DCUAAAS
    DCUCHSLIB
    FRHARM
    IEROYISA
    GWORIENT
    NJUPJS
    DCUGEORGE
    TXUGALAN
    EHARR
    MXPAZGARRO
    NYUZITA
    FLUMARINE
    MDUJUSTICE
    ENDEAVOR
    NMUBOOK
    ENKSHAPERO
    NYUTHORN
    LAUTULULIB
    PUUESNAS
    BLSILVA
    ONCCOMMON
    NEBARKHUIS
    AP-ALAYON
    CAUFLG
    CAUTARSUS
    CAUWAHRENB
    NJUALPHABK
    NCUJPARIS
    NJUGONDICA
    CAUPACKARD
    NCUMLSC
    AP-SAFIAL
    ENKATKINSO
    IEARTSCNCL
    NYUSIFRUT
    FRIIEP
    ISIDOC
    PAUDIMINO
    CCBEITUX
    WIUMLAW
    OHUWRIGHT
    DCUFRB
    DCUNCEI
    NEMDEJONGH
    TNUGRC
    BEUIA
    ENKAHARRIN
    MAUCAMSOFT
    AUWEINEK
    CAUKIQPROD
    TRTTSX
    CURNTSCI
    EXTENZA
    ATGEELONG
    MAUERNLIB
    ILUJOHNS
    MNUKHAZANA
    FLUSESCHER
    MEUGRACE
    COUWICHE
    ONCBECKER
    APPLANGLER
    FRCHAN
    LUTHERSEM
    AP-LIBPER
    NEINTCOURT
    DCUMSA
    ASTM
    TXUPUBRPER
    AGROTZAIT
    UNIVHART
    PUSHPA
    SDUAVMC
    ECFCS
    TXUSPEILL
    DEKKERIL
    UKNATARCH
    GREENBRCH
    GWZIPPRICH
    NEWSLIB
    ILSAOTA
    ILSFSCT
    WICHTIG
    AUSUNIADE
    AASHTO
    ITIUO
    ONCCIHI
    NYUCENTURY
    GTINEG
    SPUAM
    MDUATOMBKS
    MOURIVER
    NYUNURBAN
    NYUWCA
    NYUPUBLICA
    SPEGARTORR
    GWASHUBURN
    PAUSWARTH
    CAUAACM
    FRUNDERBAH
    UKDISCOVER
    MIULANDMAR
    UKBAJRA
    NESTRAAT
    ARAF
    NYUBIBLIOT
    GWINFOSOFT
    GRFILMCENT
    DCUCEMI
    TXUDISCMIN
    DCUSTIMSON
    TXUMFAH
    SPBIBMON
    NZPOLYGRAP
    ITBTF
    SADOXA
    NCUUNCCH
    AGDITELLA
    SZASTARTE
    MAUWIDEYE
    NYUCARATZA
    NAPC
    AUUTASLIB
    HKPADDYFLD
    ITBOTTEGA
    MAUCASCAD
    DCUIDB
    ORUFILMBAB
    NYUPROMULT
    IIINDLAW
    ILUAVMA
    KYUECAMPUS
    MIUMOHOLY
    ALTAMURA
    CAPIQ
    NYUEASTMAN
    CAUCLEIS
    CAUFLYFISH
    DCUAFTA
    PUBLSROW
    UKTATEPUB
    TXULAUREL
    ILURALEIGH
    DCUOTPVID
    TNUDOC
    CORNELLLRC
    ARTSCROLL
    AP-PASILOV
    CAUCHRCIN
    CAUCLORD
    DEFAFILM
    WIUAGSL
    FROZANNE
    CAUPADCELL
    CAUPERCP
    FLUYACHT
    NYUSHEFF
    NYUIRONBD
    MOUMUST
    SPMUNDUS
    NYUGUERNS
    RURPALEOG
    FRLIBLMDLP
    GWKEIPDEL
    MOVIESVILL
    ISJWG
    NYUDESIGN
    CNFAISALL
    FWHITE
    VAUNACM
    AZUFIRSTS
    NEUBOBWILL
    PAUCOPELND
    FRDECITRE
    MIUVDIAZ
    ROUSSEL
    NJUHOMSEK
    MEUYFT
    MIULIBBOSS
    NYUBONHAMS
    CAUSTANDSC
    ILUWTTW
    JABOKUTAK
    CAUMICRO
    UKHOLLETT
    MXGLANTZ
    FITAJU
    AP-SERBICA
    NYUTHSIEH
    CTUCJI
    MAUFINECUT
    ENKBLBTS
    FLURGRAMOS
    TSGRC
    UKCAMBSCH
    RUMIRKINO
    SPMAFA
    NMUSHERWD
    ATNEWINT
    NYUPMP
    KYUAPPAL
    CAUNAM
    UKUNITEDS
    GRPOLITEIA
  ]
end

def get_country_codes(conn:, api_key:)
  response = conn.get do |req|
    req.url "almaws/v1/conf/code-tables/CountryCodes"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.params['apikey'] = api_key
  end
  return nil if response.status != 200
  response.body.force_encoding('utf-8')
  JSON.parse(response.body)
end

def get_fund_by_fund_code(fund_code:, conn:, api_key:)
  response = conn.get do |req|
    req.url "almaws/v1/acq/funds"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.params['apikey'] = api_key
    req.params['q'] = "fund_code~#{fund_code}"
  end
  return nil if response.status != 200

  response.body.force_encoding('utf-8')
  doc = JSON.parse(response.body)
  return nil if doc['total_record_count'] == 0

  doc['fund'].first
end
