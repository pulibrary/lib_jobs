# frozen_string_literal: true
Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :active_record
  strategy :default

  # Other strategies:
  #
  # strategy :sequel
  # strategy :redis
  #
  # strategy :query_string
  # strategy :session
  #
  # strategy :my_strategy do |feature|
  #   # ... your custom code here; return true/false/nil.
  # end

  feature :peoplesoft_voucher,
    default: true,
    description: "Run the Peoplesoft Voucher job on a regular basis?"

  feature :alma_fund_adjustment,
    default: true,
    description: "Run the Alma Fund Adjustment job on a regular basis?"

  feature :alma_invoice_status,
    default: true,
    description: "Run the Alma Invoice Status job on a regular basis?"

  feature :alma_person_ineligible,
    default: false,
    description: "Generate the ineligible user report when the person feed runs"
end
