# frozen_string_literal: true
require 'rails_helper'

TMAS_XML = <<~'END_XML'
<?xml version='1.0' encoding='iso-8859-1'?>
<TRAFFIC>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 09:00" trafficValue="9.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 10:00" trafficValue="12.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 11:00" trafficValue="6.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 12:00" trafficValue="9.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 13:00" trafficValue="12.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 14:00" trafficValue="14.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 15:00" trafficValue="14.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 16:00" trafficValue="13.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 17:00" trafficValue="7.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 18:00" trafficValue="9.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 19:00" trafficValue="4.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - In|90852542-57E7-2F0A-DA70-66FA574583A9" trafficDate="2026-04-15 20:00" trafficValue="2.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 09:00" trafficValue="7.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 10:00" trafficValue="20.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 11:00" trafficValue="27.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 12:00" trafficValue="26.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 13:00" trafficValue="27.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 14:00" trafficValue="24.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 15:00" trafficValue="25.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 16:00" trafficValue="19.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 17:00" trafficValue="14.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 18:00" trafficValue="20.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 19:00" trafficValue="19.0" passByTrafficValue="0.0"/>
<data storeId="arch0000|Architecture - Out|C0333C35-0A2B-175C-861B-86D183460FB1" trafficDate="2026-04-15 20:00" trafficValue="9.0" passByTrafficValue="0.0"/>
<outputMessage text="Traffic Data generated successfully."/>
</TRAFFIC>
END_XML

RSpec.describe TMASGateCounts::ToAirtableHashes do
  it 'converts xml to an array of hashes' do
    expected = [[
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T09:00:00-04:00', fldwUTBK3mvfpN3Y8: 9, fldat8beQUOCWvdjm: 7 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T10:00:00-04:00', fldwUTBK3mvfpN3Y8: 12, fldat8beQUOCWvdjm: 20 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T11:00:00-04:00', fldwUTBK3mvfpN3Y8: 6, fldat8beQUOCWvdjm: 27 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T12:00:00-04:00', fldwUTBK3mvfpN3Y8: 9, fldat8beQUOCWvdjm: 26 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T13:00:00-04:00', fldwUTBK3mvfpN3Y8: 12, fldat8beQUOCWvdjm: 27 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T14:00:00-04:00', fldwUTBK3mvfpN3Y8: 14, fldat8beQUOCWvdjm: 24 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T15:00:00-04:00', fldwUTBK3mvfpN3Y8: 14, fldat8beQUOCWvdjm: 25 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T16:00:00-04:00', fldwUTBK3mvfpN3Y8: 13, fldat8beQUOCWvdjm: 19 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T17:00:00-04:00', fldwUTBK3mvfpN3Y8: 7, fldat8beQUOCWvdjm: 14 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T18:00:00-04:00', fldwUTBK3mvfpN3Y8: 9, fldat8beQUOCWvdjm: 20 } }
    ], [
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T19:00:00-04:00', fldwUTBK3mvfpN3Y8: 4, fldat8beQUOCWvdjm: 19 } },
      { fields: { fld5OFSWCZzeQb1Dq: 'Architecture', fldemkioYkKtAfesm: '2026-04-15T20:00:00-04:00', fldwUTBK3mvfpN3Y8: 2, fldat8beQUOCWvdjm: 9 } }
    ]]
    expect(described_class.new.call(TMAS_XML).value!).to eq(expected)
  end
end
