# frozen_string_literal: true

module AbsoluteIds
  class BatchImportJob < ApplicationJob
    def perform(barcode_entries:, sequence_entries:)
      @entries_by_user = {}
      @barcode_entries = barcode_entries
      @sequence_entries = sequence_entries

      emails.map do |email|
        entries = entries_by_user(email)
        user = find_user(email: email)

        batches = entries.map do |sequence_entry|
          imported = ImportJob.perform_now(sequence_entry)
          batch = ::AbsoluteId::Batch.create(absolute_ids: [imported], user: user)
          batch.save
          batch
        end

        session = ::AbsoluteId::Session.create(batches: batches, user: user)
        session.save
        session
      end
    end

    private

    def find_user(email:)
      User.find_or_create_by(email: email)
    end

    def barcode_rows
      return @barcode_rows unless @barcode_rows.nil?

      output = {}

      csv_entries = @barcode_entries[(1..-1)]
      csv_entries.each do |barcode_entry|
        primary_key = barcode_entry[0]
        output[primary_key] = barcode_entry[1]
      end

      @barcode_rows = output
    end

    def entries
      return @entries unless @entries.nil?

      csv_entries = @sequence_entries[(1..-1)]
      @entries = csv_entries.map do |sequence_entry|
        # Barcode
        barcode_key = sequence_entry[1]
        barcode = barcode_rows[barcode_key]

        # E-Mail
        email = "#{sequence_entry[7]}@princeton.edu"

        imported_attributes = {
          prefix: sequence_entry[2],
          index: sequence_entry[10],
          call_number: sequence_entry[11],
          repo_code: sequence_entry[12],
          barcode: barcode,
          email: email,
          container_indicator: sequence_entry[10]
        }

        imported_attributes
      end
    end

    def emails
      @emails ||= begin
                    entries.map { |entry| entry[:email] }
                  end
    end

    def entries_by_user(email)
      return @entries_by_user[email] unless !@entries_by_user.key?(email)

      values = entries.select { |entry| entry[:email] == email }
      @entries_by_user[email] = values
    end
  end
end
