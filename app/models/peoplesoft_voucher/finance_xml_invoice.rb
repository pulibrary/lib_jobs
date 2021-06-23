# frozen_string_literal: true
# convert alma xml invoices into finance xml
#
# The build_field_types method creates some static XML, which is really long and not changing.
#  This makes the class huge, which is why I am disabling the class length rubocop check
# rubocop:disable Metrics/ClassLength
module PeoplesoftVoucher
  class FinanceXmlInvoice
    attr_reader :xml, :alma_invoices, :invoice_list

    # @param xml [XMLBuilder] builder to insert the finance report into
    # @param alma_invoices [String] filename of the alma xml invoices
    def initialize(xml:, alma_invoice_list: nil)
      @xml = xml
      @alma_invoices = alma_invoices
      @invoice_list = alma_invoice_list
    end

    def convert
      xml.voucher_build do
        build_field_types
        xml.msgdata do
          build_peoplesoft_invoices
        end
      end
    end

    private

    def build_peoplesoft_invoices
      invoice_list.valid_invoices.each do |invoice|
        voucher_id = invoice.voucher_id

        xml.transaction do
          xml.vchr_hdr_stg(class: 'R') do
            build_invoice_header(invoice: invoice, voucher_id: voucher_id)
            build_invoice(invoice: invoice, voucher_id: voucher_id)
          end
          build_invoice_footer
        end
      end
    end

    def build_invoice(invoice:, voucher_id:)
      invoice.line_items.each_with_index do |line_item, line_idx|
        line_no = (line_idx + 1).to_s
        line_item[:fund_list].each do |fund|
          build_voucher(line_no: line_no, line_item: line_item, fund: fund, voucher_id: voucher_id)
        end
      end
    end

    def build_voucher(line_no:, line_item:, fund:, voucher_id:)
      xml.vchr_line_stg(class: 'r') do
        xml.business_unit "PRINU"
        xml.voucher_line_num line_no
        xml.descr (line_item[:po_line_number]).to_s
        xml.merchandise_amt (fund[:usd_amount]).to_s
        xml.business_unit_gl "PRINU"
        xml.voucher_id voucher_id
        xml.descr254_mixed (line_item[:title]).to_s
        build_voucher_distribution(line_no: line_no, line_item: line_item, fund: fund, voucher_id: voucher_id)
      end
    end

    # I believe the xml build is messing with the ABC size here
    # rubocop:disable Metrics/AbcSize
    def build_voucher_distribution(line_no:, line_item:, fund:, voucher_id:)
      xml.vchr_dist_stg(class: 'r') do
        xml.business_unit "PRINU"
        xml.voucher_line_num line_no
        xml.distrib_line_num "1"
        xml.business_unit_gl "PRINU"
        xml.account (line_item[:reporting_code]).to_s
        xml.deptid (fund[:prime_dept]).to_s
        xml.merchandise_amt (fund[:usd_amount]).to_s
        xml.fund_code (fund[:prime_fund]).to_s
        xml.program_code (fund[:prime_program]).to_s
        xml.voucher_id voucher_id
      end
    end

    def build_invoice_header(invoice:, voucher_id:)
      xml.business_unit "PRINU"
      xml.voucher_id voucher_id
      xml.voucher_style "REG"
      xml.invoice_id invoice.id.to_s
      xml.invoice_dt invoice.invoice_date
      xml.vendor_id invoice.vendor_id
      xml.invoice_rcpt_dt invoice.invoice_create_date
      xml.origin 'LIB'
      xml.vchr_src 'XML'
      xml.gross_amt invoice.invoice_local_amount_total.to_s
      xml.vndr_loc invoice.vendor_location
      xml.pymnt_terms_cd "IMM"
      xml.descr254_mixed header_description(invoice: invoice)
      build_invoice_header_payment(voucher_id: voucher_id)
    end
    # rubocop:enable Metrics/AbcSize

    def header_description(invoice:)
      return invoice.unique_identifier if invoice.payment_message.blank?
      "#{invoice.unique_identifier}|#{invoice.payment_message}"
    end

    def build_invoice_header_payment(voucher_id:)
      xml.vchr_pymt_stg(class: 'R') do
        xml.business_unit "PRINU"
        xml.pymnt_cnt "1"
        xml.voucher_id voucher_id
      end
    end

    def build_invoice_footer
      xml.pscama(class: 'r') do
        xml.language_cd!
        xml.audit_actn "A"
        xml.base_language_cd "ENG"
        xml.msg_seq_flg!
        xml.process_instance "0"
        xml.publish_rule_id!
        xml.msgnodename!
      end
    end

    # This is a horrible method, but it sets up some XML that does not seem like it will change in the near future
    #  I'm just leaving it be for that reason and disabling the rubocop checks
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/BlockLength
    def build_field_types
      xml.fieldtypes do
        xml.vchr_bank_stg(class: 'r') do # not provided
          xml.business_unit(type: 'char')
          xml.voucher_id(type: 'char')
          xml.bank_id_qual(type: 'char')
          xml.bnk_id_nbr(type: 'char')
          xml.branch_id(type: 'char')
          xml.bank_acct_type(type: 'char')
          xml.bank_account_num(type: 'char')
          xml.check_digit(type: 'char')
          xml.dfi_id_qual(type: 'char')
          xml.dfi_id_num(type: 'char')
          xml.beneficiary_bank(type: 'char')
          xml.beneficiary_bnk_ac(type: 'char')
          xml.benef_branch(type: 'char')
          xml.benef_branch_ac(type: 'char')
          xml.country(type: 'char')
          xml.address1(type: 'char')
          xml.address2(type: 'char')
          xml.address3(type: 'char')
          xml.address4(type: 'char')
          xml.city(type: 'char')
          xml.num1(type: 'char')
          xml.num2(type: 'char')
          xml.house_type(type: 'char')
          xml.addr_field1(type: 'char')
          xml.addr_field2(type: 'char')
          xml.addr_field3(type: 'char')
          xml.county(type: 'char')
          xml.state(type: 'char')
          xml.postal(type: 'char')
          xml.geo_code(type: 'char')
          xml.in_city_limit(type: 'char')
          xml.country_code(type: 'char')
          xml.phone(type: 'char')
          xml.extension(type: 'char')
          xml.fax(type: 'char')
          xml.iban_check_digit(type: 'char')
          xml.eft_pymnt_fmt_cd(type: 'char')
          xml.eft_trans_handling(type: 'char')
          xml.eft_dom_costs_cd(type: 'char')
          xml.eft_corr_costs_cd(type: 'char')
          xml.eft_check_draw_cd(type: 'char')
          xml.eft_check_fwrd_cd(type: 'char')
          xml.eft_pay_inst_cd1(type: 'char')
        end
        xml.vchr_ibank_stg(class: 'r') do # not provided
          xml.business_unit(type: 'char')
          xml.voucher_id(type: 'char')
          xml.intrmed_seq_no(type: 'number')
          xml.intrmed_bank_cd(type: 'char')
          xml.intrmed_acct_key(type: 'char')
          xml.intrmed_dfi_id(type: 'char')
          xml.intrmed_pymnt_msg(type: 'char')
          xml.stl_routing_method(type: 'char')
        end
        xml.vchr_vndr_stg(class: 'r') do # not provided
          xml.business_unit(type: 'char')
          xml.voucher_id(type: 'char')
          xml.name1(type: 'char')
          xml.emailid(type: 'char')
          xml.country(type: 'char')
          xml.address1(type: 'char')
          xml.address2(type: 'char')
          xml.address3(type: 'char')
          xml.address4(type: 'char')
          xml.city(type: 'char')
          xml.num1(type: 'char')
          xml.num2(type: 'char')
          xml.house_type(type: 'char')
          xml.addr_field1(type: 'char')
          xml.addr_field2(type: 'char')
          xml.addr_field3(type: 'char')
          xml.county(type: 'char')
          xml.state(type: 'char')
          xml.postal(type: 'char')
          xml.geo_code(type: 'char')
          xml.in_city_limit(type: 'char')
        end
        xml.vchr_hdr_stg(class: 'r') do # provided
          xml.business_unit(type: 'char') # static
          xml.voucher_id(type: 'char') # invoice.voucher_id
          xml.voucher_style(type: 'char') # static
          xml.invoice_id(type: 'char') # invoice.id
          xml.invoice_dt(type: 'date') # invoice.invoice_date
          xml.vendor_id(type: 'char') # invoice.vendor_id
          xml.vndr_loc(type: 'char') # invoice.vendor_location
          xml.address_seq_num(type: 'number') # not used
          xml.grp_ap_id(type: 'char') # not used
          xml.origin(type: 'char') # static
          xml.oprid(type: 'char') # not used
          xml.accounting_dt(type: 'date') # not used
          xml.post_voucher(type: 'char') # not used
          xml.dst_cntrl_id(type: 'char') # not used
          xml.voucher_id_related(type: 'char') # not used
          xml.gross_amt(type: 'number') # invoice_local_amt_total
          xml.dscnt_amt(type: 'number') # not used
          xml.tax_exempt(type: 'char') # not used
          xml.saletx_amt(type: 'number') # not used
          xml.freight_amt(type: 'number') # not used
          xml.misc_amt(type: 'number') # not used
          xml.pymnt_terms_cd(type: 'char') # static
          xml.entered_dt(type: 'date') # not used
          xml.txn_currency_cd(type: 'char') # not used
          xml.rt_type(type: 'char') # not used
          xml.rate_mult(type: 'number') # not used
          xml.rate_div(type: 'number') # not used
          xml.vat_entrd_amt(type: 'number') # not used
          xml.match_action(type: 'char') # not used
          xml.cur_rt_source(type: 'char') # not used
          xml.dscnt_amt_flg(type: 'char') # not used
          xml.due_dt_flg(type: 'char') # not used
          xml.vchr_apprvl_flg(type: 'char') # not used
          xml.busprocname(type: 'char') # not used
          xml.appr_rule_set(type: 'char') # not used
          xml.vat_dclrtn_point(type: 'char') # not used
          xml.vat_calc_type(type: 'char') # not used
          xml.vat_calc_gross_net(type: 'char') # not used
          xml.vat_recalc_flg(type: 'char') # not used
          xml.vat_calc_frght_flg(type: 'char') # not used
          xml.vat_treatment_grp(type: 'char') # not used
          xml.country_ship_from(type: 'char') # not used
          xml.state_ship_from(type: 'char') # not used
          xml.country_ship_to(type: 'char') # not used
          xml.state_ship_to(type: 'char') # not used
          xml.country_vat_billfr(type: 'char') # not used
          xml.country_vat_billto(type: 'char') # not used
          xml.vat_excptn_certif(type: 'char') # not used
          xml.vat_round_rule(type: 'char') # not used
          xml.country_loc_seller(type: 'char') # not used
          xml.state_loc_seller(type: 'char') # not used
          xml.country_loc_buyer(type: 'char') # not used
          xml.state_loc_buyer(type: 'char') # not used
          xml.country_vat_supply(type: 'char') # not used
          xml.state_vat_supply(type: 'char') # not used
          xml.country_vat_perfrm(type: 'char') # not used
          xml.state_vat_perfrm(type: 'char') # not used
          xml.state_vat_default(type: 'char') # not used
          xml.prepaid_ref(type: 'char') # not used
          xml.prepaid_auto_apply(type: 'char') # not used
          xml.descr254_mixed(type: 'char') # invoice.unique_identifier| invoice.payment_note
          xml.ein_federal(type: 'char') # not used
          xml.ein_state_local(type: 'char') # not used
          xml.business_unit_po(type: 'char') # not used
          xml.po_id(type: 'char') # not used
          xml.packslip_no(type: 'char') # not used
          xml.pay_trm_bse_dt_opt(type: 'char') # not used
          xml.vat_calc_misc_flg(type: 'char') # not used
          xml.pay_schedule_type(type: 'char') # not used
          xml.tax_grp(type: 'char') # not used
          xml.tax_pymnt_type(type: 'char') # not used
          xml.inspect_dt(type: 'date') # not used
          xml.invoice_rcpt_dt(type: 'date') # invoice.invoice_create_date
          xml.receipt_dt(type: 'date') # not used
          xml.bill_of_lading(type: 'char') # not used
          xml.carrier_id(type: 'char') # not used
          xml.doc_type(type: 'char') # not used
          xml.dscnt_due_dt(type: 'date') # not used
          xml.dscnt_prorate_flg(type: 'char') # not used
          xml.due_dt(type: 'date') # not used
          xml.frght_charge_code(type: 'char') # not used
          xml.lc_id(type: 'char') # not used
          xml.misc_charge_code(type: 'char') # not used
          xml.remit_addr_seq_num(type: 'number') # not used
          xml.saletx_charge_code(type: 'char') # not used
          xml.vchr_bld_code(type: 'char') # not used
          xml.business_unit_ar(type: 'char') # not used
          xml.cust_id(type: 'char') # not used
          xml.item(type: 'char') # not used
          xml.item_line(type: 'number') # not used
          xml.vchr_src(type: 'char') # Always 'XML'
          xml.vat_excptn_type(type: 'char') # not used
          xml.user_vchr_char1(type: 'char') # not used
          xml.user_vchr_char2(type: 'char') # not used
          xml.user_vchr_dec(type: 'number') # not used
          xml.user_vchr_date(type: 'date') # not used
          xml.user_vchr_num1(type: 'number') # not used
          xml.user_hdr_char1(type: 'char') # not used
          xml.vchr_line_stg(class: 'r') do # provided
            xml.business_unit(type: 'char') # static
            xml.voucher_id(type: 'char') # invoice.voucher_id
            xml.voucher_line_num(type: 'number') # auto-generated
            xml.business_unit_po(type: 'char') # not used
            xml.po_id(type: 'char') # not used
            xml.line_nbr(type: 'number') # not used
            xml.sched_nbr(type: 'number') # not used
            xml.descr(type: 'char') # line_item[:po_line_number]
            xml.merchandise_amt(type: 'number') # fund[:usd_amount]
            xml.itm_setid(type: 'char') # not used
            xml.inv_item_id(type: 'char') # not used
            xml.qty_vchr(type: 'number') # not used
            xml.statistic_amount(type: 'number') # not used
            xml.unit_of_measure(type: 'char') # not used
            xml.unit_price(type: 'number') # not used
            xml.dscnt_appl_flg(type: 'char') # not used
            xml.tax_cd_vat(type: 'char') # not used
            xml.business_unit_recv(type: 'char') # not used
            xml.receiver_id(type: 'char') # not used
            xml.recv_ln_nbr(type: 'number') # not used
            xml.recv_ship_seq_nbr(type: 'number') # not used
            xml.match_line_opt(type: 'char') # not used
            xml.distrib_mthd_flg(type: 'char') # not used
            xml.shipto_id(type: 'char') # not used
            xml.sut_base_id(type: 'char') # not used
            xml.tax_cd_sut(type: 'char') # not used
            xml.ultimate_use_cd(type: 'char') # not used
            xml.sut_excptn_type(type: 'char') # not used
            xml.sut_excptn_certif(type: 'char') # not used
            xml.sut_applicability(type: 'char') # not used
            xml.vat_applicability(type: 'char') # not used
            xml.vat_txn_type_cd(type: 'char') # not used
            xml.vat_use_id(type: 'char') # not used
            xml.addr_seq_num_ship(type: 'number') # not used
            xml.descr254_mixed(type: 'char') # line_item[:title]
            xml.business_unit_gl(type: 'char') # 'PRINU'
            xml.account(type: 'char') # not used
            xml.altacct(type: 'char') # not used
            xml.operating_unit(type: 'char') # not used
            xml.product(type: 'char') # not used
            xml.fund_code(type: 'char') # not used
            xml.class_fld(type: 'char') # not used
            xml.program_code(type: 'char') # not used
            xml.budget_ref(type: 'char') # not used
            xml.affiliate(type: 'char') # not used
            xml.affiliate_intra1(type: 'char') # not used
            xml.affiliate_intra2(type: 'char') # not used
            xml.chartfield1(type: 'char') # not used
            xml.chartfield2(type: 'char') # not used
            xml.chartfield3(type: 'char') # not used
            xml.deptid(type: 'char') # not used
            xml.project_id(type: 'char') # not used
            xml.business_unit_pc(type: 'char') # not used
            xml.activity_id(type: 'char') # not used
            xml.analysis_type(type: 'char') # not used
            xml.resource_type(type: 'char') # not used
            xml.resource_category(type: 'char') # not used
            xml.resource_sub_cat(type: 'char') # not used
            xml.tax_dscnt_flg(type: 'char') # not used
            xml.tax_frght_flg(type: 'char') # not used
            xml.tax_misc_flg(type: 'char') # not used
            xml.tax_vat_flg(type: 'char') # not used
            xml.physical_nature(type: 'char') # not used
            xml.vat_rcrd_inpt_flg(type: 'char') # not used
            xml.vat_rcrd_outpt_flg(type: 'char') # not used
            xml.vat_treatment(type: 'char') # not used
            xml.vat_svc_supply_flg(type: 'char') # not used
            xml.vat_service_type(type: 'char') # not used
            xml.country_loc_buyer(type: 'char') # not used
            xml.state_loc_buyer(type: 'char') # not used
            xml.country_loc_seller(type: 'char') # not used
            xml.state_loc_seller(type: 'char') # not used
            xml.country_vat_supply(type: 'char') # not used
            xml.state_vat_supply(type: 'char') # not used
            xml.country_vat_perfrm(type: 'char') # not used
            xml.state_vat_perfrm(type: 'char') # not used
            xml.state_ship_from(type: 'char') # not used
            xml.state_vat_default(type: 'char') # not used
            xml.requestor_id(type: 'char') # not used
            xml.wthd_sw(type: 'char') # not used
            xml.wthd_cd(type: 'char') # not used
            xml.mfg_id(type: 'char') # not used
            xml.user_vchr_char1(type: 'char') # not used
            xml.user_vchr_char2(type: 'char') # not used
            xml.user_vchr_dec(type: 'number') # not used
            xml.user_vchr_date(type: 'date') # not used
            xml.user_vchr_num1(type: 'number') # not used
            xml.user_line_char1(type: 'char') # not used
            xml.user_sched_char1(type: 'char') # not used
            xml.vchr_dist_stg(class: 'r') do
              xml.business_unit(type: 'char') # static
              xml.voucher_id(type: 'char') # invoice.voucher_id
              xml.voucher_line_num(type: 'number') # auto-generated
              xml.distrib_line_num(type: 'number') # always 1
              xml.business_unit_gl(type: 'char') # 'PRINU'
              xml.account(type: 'char') # line_item[:prime_account]
              xml.altacct(type: 'char') # not used
              xml.deptid(type: 'char') # fund[:prime_dept]
              xml.statistics_code(type: 'char') # not used
              xml.statistic_amount(type: 'number') # not used
              xml.qty_vchr(type: 'number') # not used
              xml.descr(type: 'char') # not used
              xml.merchandise_amt(type: 'number') # fund[:usd_amount]
              xml.business_unit_po(type: 'char') # not used
              xml.po_id(type: 'char') # not used
              xml.line_nbr(type: 'number') # not used
              xml.sched_nbr(type: 'number') # not used
              xml.po_dist_line_num(type: 'number') # not used
              xml.business_unit_pc(type: 'char') # not used
              xml.activity_id(type: 'char') # not used
              xml.analysis_type(type: 'char') # not used
              xml.resource_type(type: 'char') # not used
              xml.resource_category(type: 'char') # not used
              xml.resource_sub_cat(type: 'char') # not used
              xml.asset_flg(type: 'char') # not used
              xml.business_unit_am(type: 'char') # not used
              xml.asset_id(type: 'char') # not used
              xml.profile_id(type: 'char') # not used
              xml.cost_type(type: 'char') # not used
              xml.vat_txn_type_cd(type: 'char') # not used
              xml.recv_dist_line_num(type: 'number') # not used
              xml.operating_unit(type: 'char') # not used
              xml.product(type: 'char') # not used
              xml.fund_code(type: 'char') # fund[:prime_fund]
              xml.class_fld(type: 'char') # not used
              xml.program_code(type: 'char') # fund[:prime_program]
              xml.budget_ref(type: 'char') # not used
              xml.affiliate(type: 'char') # not used
              xml.affiliate_intra1(type: 'char') # not used
              xml.affiliate_intra2(type: 'char') # not used
              xml.chartfield1(type: 'char') # not used
              xml.chartfield2(type: 'char') # not used
              xml.chartfield3(type: 'char') # not used
              xml.project_id(type: 'char') # not used
              xml.budget_dt(type: 'date') # not used
              xml.entry_event(type: 'char') # not used
              xml.jrnl_ln_ref(type: 'char') # not used
              xml.vat_aport_cntrl(type: 'char') # not used
              xml.user_vchr_char1(type: 'char') # not used
              xml.user_vchr_char2(type: 'char') # not used
              xml.user_vchr_dec(type: 'number') # not used
              xml.user_vchr_date(type: 'date') # not used
              xml.user_vchr_num1(type: 'number') # not used
              xml.user_dist_char1(type: 'char') # not used
              xml.open_item_key(type: 'char') # not used
            end
          end
          xml.vchr_pymt_stg(class: 'r') do # provided
            xml.business_unit(type: 'char') # 'PRINU'
            xml.voucher_id(type: 'char') # invoice.voucher_id
            xml.pymnt_cnt(type: 'number')
            xml.bank_cd(type: 'char')
            xml.bank_acct_key(type: 'char')
            xml.pymnt_method(type: 'char')
            xml.pymnt_message(type: 'char')
            xml.pymnt_handling_cd(type: 'char')
            xml.pymnt_hold(type: 'char')
            xml.pymnt_hold_reason(type: 'char')
            xml.message_cd(type: 'char')
            xml.pymnt_gross_amt(type: 'number')
            xml.pymnt_separate(type: 'char')
            xml.scheduled_pay_dt(type: 'date')
            xml.pymnt_group_cd(type: 'char')
            xml.eft_layout_cd(type: 'char')
          end
        end
        xml.vchr_msch_stg(class: 'r') do
          xml.business_unit(type: 'char')
          xml.voucher_id(type: 'char')
          xml.dst_acct_type(type: 'char')
          xml.misc_charge_code(type: 'char')
          xml.misc_chrg_amt(type: 'number')
        end
        xml.pscama(class: 'r') do
          xml.language_cd(type: 'char')
          xml.audit_actn(type: 'char')
          xml.base_language_cd(type: 'char')
          xml.msg_seq_flg(type: 'char')
          xml.process_instance(type: 'number')
          xml.publish_rule_id(type: 'char')
          xml.msgnodename(type: 'char')
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/BlockLength
  end
end
# rubocop:enable Metrics/ClassLength
