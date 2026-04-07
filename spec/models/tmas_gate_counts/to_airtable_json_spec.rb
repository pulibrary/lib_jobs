# frozen_string_literal: true
require 'rails_helper'

TMAS_XML = <<~'END_XML'
<?xml version='1.0' encoding='iso-8859-1'?>
<TRAFFIC>
<data storeId="LEWIS" trafficDate="2026-04-01 00:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 01:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 02:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 03:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 04:00" trafficValue="1.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 05:00" trafficValue="2.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 06:00" trafficValue="12.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 07:00" trafficValue="6.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 08:00" trafficValue="41.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 09:00" trafficValue="86.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 10:00" trafficValue="128.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 11:00" trafficValue="48.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 12:00" trafficValue="80.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 13:00" trafficValue="90.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 14:00" trafficValue="70.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 15:00" trafficValue="41.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 16:00" trafficValue="67.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 17:00" trafficValue="25.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 18:00" trafficValue="21.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 19:00" trafficValue="24.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 20:00" trafficValue="18.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 21:00" trafficValue="1.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 22:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<data storeId="LEWIS" trafficDate="2026-04-01 23:00" trafficValue="0.0" passByTrafficValue="0.0"/>
<outputMessage text="Traffic Data generated successfully."/>
</TRAFFIC>
END_XML

RSpec.describe TMASGateCounts::ToAirtableJson do
  it 'converts xml to json' do
    expected = [[
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T00:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T01:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T02:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T03:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T04:00:00-04:00', fldwUTBK3mvfpN3Y8: 1 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T05:00:00-04:00', fldwUTBK3mvfpN3Y8: 2 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T06:00:00-04:00', fldwUTBK3mvfpN3Y8: 12 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T07:00:00-04:00', fldwUTBK3mvfpN3Y8: 6 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T08:00:00-04:00', fldwUTBK3mvfpN3Y8: 41 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T09:00:00-04:00', fldwUTBK3mvfpN3Y8: 86 }
    ].to_json, [
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T10:00:00-04:00', fldwUTBK3mvfpN3Y8: 128 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T11:00:00-04:00', fldwUTBK3mvfpN3Y8: 48 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T12:00:00-04:00', fldwUTBK3mvfpN3Y8: 80 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T13:00:00-04:00', fldwUTBK3mvfpN3Y8: 90 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T14:00:00-04:00', fldwUTBK3mvfpN3Y8: 70 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T15:00:00-04:00', fldwUTBK3mvfpN3Y8: 41 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T16:00:00-04:00', fldwUTBK3mvfpN3Y8: 67 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T17:00:00-04:00', fldwUTBK3mvfpN3Y8: 25 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T18:00:00-04:00', fldwUTBK3mvfpN3Y8: 21 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T19:00:00-04:00', fldwUTBK3mvfpN3Y8: 24 }

    ].to_json, [
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T20:00:00-04:00', fldwUTBK3mvfpN3Y8: 18 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T21:00:00-04:00', fldwUTBK3mvfpN3Y8: 1 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T22:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 },
      { fld5OFSWCZzeQb1Dq: 'Lewis and Engineering', fldemkioYkKtAfesm: '2026-04-01T23:00:00-04:00', fldwUTBK3mvfpN3Y8: 0 }

    ].to_json]
    expect(described_class.new.call(TMAS_XML).value!).to eq(expected)
  end
end
