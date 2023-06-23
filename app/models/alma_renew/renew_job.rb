# frozen_string_literal: true

module AlmaRenew
  class RenewJob < LibJob
    attr_reader :alma_ncip_uri, :renew_list
    attr_accessor :errors, :valid_item_count

    # outputs are ncip requests
    # the inputs is a file(s) on the alma ftp site read in via AlmaRenew::RenewList
    def initialize(renew_list: AlmaRenew::AlmaRenewList.new,
                   alma_ncip_url: LibJobs.config[:ncip_renew_alma_url])
      super(category: "AlmaRenew")

      @alma_ncip_uri = URI(alma_ncip_url)
      @renew_list = renew_list
      @errors = []
      @valid_item_count = 0
    end

    private

    def handle(data_set:)
      Net::HTTP.start(alma_ncip_uri.host, alma_ncip_uri.port, use_ssl: true) do |http|
        renew_items(http)
      end
      renew_list.mark_files_as_processed
      data_set.data = report
      data_set.report_time = Time.zone.now
      data_set
    end

    def renew_items(http)
      renew_list.renew_item_list.each do |item|
        unless item.valid?
          item_error_messages = item.errors.full_messages.join(", ")
          errors << "#{item_error_messages} (Barcode: #{item.item_barcode})"
          next
        end
        @valid_item_count += 1
        ncip_request = ncip_request(item:)
        ncip_renew_item(ncip_request, http, item)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def ncip_renew_item(request, http, item)
      retries ||= 0
      response = http.request request
      if response.is_a? Net::HTTPOK
        process_ncip_response(response)
      else
        errors << response.body
      end
    rescue Net::ReadTimeout => error
      while (retries += 1) <= 2
        Rails.logger.warn("Encountered #{error.class}: '#{error.message}' when renewing item with barcode: #{item.item_barcode} at #{Time.now.utc}, retrying in #{retries} second(s)...")
        sleep(retries)
        retry
      end
      errors << "Encountered #{error.class}: Renewal unsuccessful for item with barcode: #{item.item_barcode}"
      Rails.logger.error("Encountered #{error.class}: '#{error.message}' at #{Time.now.utc}, unsuccessful in renewing item with barcode: #{item.item_barcode} after #{retries} retries")
    end
    # rubocop:enable Metrics/MethodLength

    def process_ncip_response(response)
      doc = Nokogiri::XML(response.body)
      name_space = doc.namespaces.keys.first[6..]
      return unless doc.xpath("//#{name_space}:ItemId").empty?

      errors << "#{doc.xpath("//#{name_space}:Problem/#{name_space}:ProblemDetail").text}" \
                " (#{doc.xpath("//#{name_space}:Problem/#{name_space}:ProblemValue").text})"
    end

    def ncip_request(item:)
      request = Net::HTTP::Post.new alma_ncip_uri.path
      request.body = item.ncip
      request['Content-Type'] = 'text/xml'
      request['Accept'] = 'text/xml'
      request
    end

    def report
      item_count = renew_list.renew_item_list.count

      if errors.empty?
        "Renewals were successfully sent for #{item_count} items"
      else
        "We received #{item_count} renewal requests. We tried to send renewals for #{valid_item_count} items. #{errors.count} errors were encountered.\n #{errors.join("\n")}"
      end
    end
  end
end
