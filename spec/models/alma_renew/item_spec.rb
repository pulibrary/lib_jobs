# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::Item, type: :model do
  subject(:item) { described_class.new({ "Barcode" => item_id, "Patron Group" => user_group, "Primary Identifier" => user_id, "Expiry Date" => expiration_date }) }

  let(:item_id) { "23915763110006421" }
  let(:user_group) { "UGRD Undergraduate" }
  let(:user_id) { "999999999" }
  let(:expiration_date) { 2.years.from_now }

  describe "#to_h" do
    let(:source_item_hash) { { "Barcode" => "32044061963013", "Patron Group" => "UGRD Undergraduate", "Expiry Date" => "2023-10-31", "Primary Identifier" => "999999999" } }
    let(:item) { described_class.new(source_item_hash) }

    it "can translate the item to and from a hash" do
      expect(item.to_h).to eq source_item_hash
    end
  end

  describe "ncip" do
    let(:xml) do
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" \
      "<ns1:NCIPMessage xmlns:ns1=\"http://www.niso.org/2008/ncip\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" \
      " ns1:version=\"http://www.niso.org/schemas/ncip/v2_0/imp1/xsd/ncip_v2_0.xsd\">\n" \
      "  <ns1:RenewItem>\n" \
      "    <ns1:InitiationHeader>\n" \
      "      <ns1:FromAgencyId>\n" \
      "        <ns1:AgencyId>01PRI_INST</ns1:AgencyId>\n" \
      "      </ns1:FromAgencyId>\n" \
      "      <ns1:ToAgencyId>\n" \
      "        <ns1:AgencyId>01PRI_INST</ns1:AgencyId>\n" \
      "      </ns1:ToAgencyId>\n" \
      "      <ns1:ApplicationProfileType>SCSB</ns1:ApplicationProfileType>\n" \
      "    </ns1:InitiationHeader>\n" \
      "    <ns1:UserId>\n" \
      "      <ns1:UserIdentifierValue>#{user_id}</ns1:UserIdentifierValue>\n" \
      "    </ns1:UserId>\n" \
      "    <ns1:ItemId>\n" \
      "      <ns1:ItemIdentifierValue>#{item_id}</ns1:ItemIdentifierValue>\n" \
      "    </ns1:ItemId>\n" \
      "    <ns1:DesiredDateDue>#{due_date.strftime('%Y-%m-%dT19:00:00-05:00')}</ns1:DesiredDateDue>\n" \
      "  </ns1:RenewItem>\n" \
      "</ns1:NCIPMessage>\n"
    end
    let(:due_date) { 56.days.from_now }
    it "translates to ncip and calculates the renew date" do
      expect(item.ncip).to eq(xml)
    end

    context "Undergraduate with close expiration date" do
      let(:expiration_date) { 10.days.from_now }
      let(:due_date) { expiration_date }

      it "translates to ncip and calculates the renew date as the expiration date" do
        expect(item.ncip).to eq(xml)
      end
    end

    context "regular staff" do
      let(:user_group) { "REG Regular Staff" }

      it "translates to ncip and calculates the renew date" do
        expect(item.ncip).to eq(xml)
      end

      context "close expiration date" do
        let(:expiration_date) { 10.days.from_now }
        let(:due_date) { expiration_date }

        it "translates to ncip and calculates the renew date as the expiration date" do
          expect(item.ncip).to eq(xml)
        end
      end
    end

    describe "validating renewal items" do
      context "with all required fields" do
        it "validates the item" do
          expect(item.valid?).to be true
          expect(item.errors.empty?).to be true
          expect(item.errors.full_messages).to be_empty
        end
      end
      context "with a nil expiration date" do
        let(:expiration_date) { nil }

        it "does not validate the item" do
          expect(item.valid?).to be false
          expect(item.errors.empty?).to be false
          expect(item.errors.full_messages).to match_array(["Expiration date cannot be blank"])
        end
      end
      context "when the primary identifier / user_id is 'None'" do
        let(:user_id) { "None" }

        it "does not validate the item" do
          expect(item.valid?).to be false
          expect(item.errors.empty?).to be false
          expect(item.errors.full_messages).to match_array(["User cannot be 'None'"])
        end
      end
    end

    context "no expiration date" do
      let(:expiration_date) { nil }
      it "does not raise an ArgumentError" do
        expect { item.ncip }.not_to raise_error
      end
    end

    context "Senior" do
      let(:user_group) { "SENR Senior Undergraduate" }
      let(:today) { DateTime.now }
      context "today is before May 10th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 4, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year, 5, 10) }

        it "translates to ncip and calculates the renew date as 5/10 of this year" do
          expect(item.ncip).to eq(xml)
        end

        context "close expiration date" do
          let(:expiration_date) { 10.days.from_now }
          let(:due_date) { expiration_date }

          it "translates to ncip and calculates the renew date as the expiration date" do
            expect(item.ncip).to eq(xml)
          end
        end
      end

      context "today is after May 10th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 6, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 5, 10) }

        it "translates to ncip and calculates the renew date as as 5/10 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end

      context "today is May 10th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 5, 10))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 5, 10) }

        it "translates to ncip and calculates the renew date as as 5/10 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end
    end

    context "Graduate Student" do
      let(:user_group) { "GRAD Graduate Student" }
      let(:today) { DateTime.now }
      context "today is before April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 4, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year, 6, 15) }

        it "translates to ncip and calculates the renew date as 6/15 of this year" do
          expect(item.ncip).to eq(xml)
        end

        context "close expiration date" do
          let(:expiration_date) { 10.days.from_now }
          let(:due_date) { expiration_date }

          it "translates to ncip and calculates the renew date as the expiration date" do
            expect(item.ncip).to eq(xml)
          end
        end
      end

      context "today is after April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 6, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 6, 15) }

        it "translates to ncip and calculates the renew date as as 6/15 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end

      context "today is April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 4, 30))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 6, 15) }

        it "translates to ncip and calculates the renew date as as 6/15 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end
    end

    context "Faculty" do
      let(:user_group) { "P Faculty & Professional" }
      let(:today) { DateTime.now }
      context "today is before April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 4, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year, 6, 15) }

        it "translates to ncip and calculates the renew date as 6/15 of this year" do
          expect(item.ncip).to eq(xml)
        end

        context "close expiration date" do
          let(:expiration_date) { 10.days.from_now }
          let(:due_date) { expiration_date }

          it "translates to ncip and calculates the renew date as the expiration date" do
            expect(item.ncip).to eq(xml)
          end
        end
      end

      context "today is after April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 6, 1))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 6, 15) }

        it "translates to ncip and calculates the renew date as as 6/15 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end

      context "today is April 30th" do
        before do
          Timecop.freeze(DateTime.new(today.year, 4, 30))
        end

        after do
          Timecop.return
        end

        let(:due_date) { DateTime.new(today.year + 1, 6, 15) }

        it "translates to ncip and calculates the renew date as as 6/15 of next year" do
          expect(item.ncip).to eq(xml)
        end
      end
    end

    context "Guests" do
      let(:user_group) { "GST Guest Patron" }
      let(:due_date) { 28.days.from_now }

      it "translates to ncip and calculates the renew date" do
        expect(item.ncip).to eq(xml)
      end

      context "close expiration date" do
        let(:expiration_date) { 10.days.from_now }
        let(:due_date) { expiration_date }

        it "translates to ncip and calculates the renew date as the expiration date" do
          expect(item.ncip).to eq(xml)
        end
      end
    end
  end
end
