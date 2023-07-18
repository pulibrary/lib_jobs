# frozen_string_literal: true

module Oclc
  # rubocop:disable Metrics/ClassLength
  class Record
    attr_reader :record
    def initialize(marc_record:)
      @record = marc_record
    end

    def generally_relevant?
      !juvenile? && !audiobook? && !computer_file? && !published_in_us_uk_or_canada? && within_last_two_years?
    end

    def relevant_to_selector?(selector:)
      call_number_in_range_for_selector?(selector:) || subject_relevant_to_selector?(selector:)
    end

    def call_number_in_range_for_selector?(selector:)
      return false unless class_relevant_to_selector?(selector:)

      selector.call_number_ranges.map do |range|
        next false unless lc_class == range[:class]

        next true if lc_number.between?(range[:low_num], range[:high_num])

        false
      end.include?(true)
    end

    def class_relevant_to_selector?(selector:)
      return true if selector.classes.include?(lc_class)

      false
    end

    def subject_relevant_to_selector?(selector:)
      subjects.any? { |subject| subject.downcase.match?(/#{selector.subjects.join('|')}/) }
    end

    def oclc_id
      record['001'].value.strip
    end

    def isbns
      isbn = []
      record.fields('020').each do |field|
        next unless field['a']

        isbn << StdNum::ISBN.normalize(field.value)
      end
      isbn.uniq
    end

    # The LC classification number (050 subfield a) stripped of whitespace
    def call_number
      return nil unless record['050']

      targets = record['050'].subfields.select do |subfield|
        %w[a b].include?(subfield.code)
      end
      return nil if targets.empty?

      targets.map(&:value).join(' ')
    end

    # Only the class from the call_number
    def lc_class
      return unless call_number

      call_number.gsub(/^([A-Z]+?)[^A-Z].*$/, '\1')
    end

    # Only the number from the call_number
    def lc_number
      return unless call_number

      call_number.gsub(/^[^0-9]+([0-9]+)(\.[0-9]+)?[^0-9]?.*$/, '\1\2').to_f
    end

    def languages
      f008_language = record['008'].value[35..37]
      languages = [f008_language]
      languages += f041_languages if f041_languages.present?
      languages.uniq
    end

    def f041_languages
      return nil unless record['041']

      record.fields('041').map { |field| field.subfields.map(&:value) }.flatten.uniq
    end

    def subjects
      subjects = []
      subject_fields = record.fields('600'..'699').select do |field|
        field.indicator2 == '0' || (field.indicator2 == '7' && %w[lcgft aat].include?(field['2']))
      end
      return subjects if subject_fields.empty?
      subject_fields.each do |field|
        subjects << field.map { |f| scrub_string(f.value) }
      end
      subjects.flatten.uniq
    end

    def audiobook?
      target_fields = record.fields('250'..'259')
      return false if target_fields.empty?

      terms = record.fields('250'..'259').map { |field| field.subfields.map(&:value) }.flatten
      terms.map { |term| scrub_string(term) }.uniq.include?('audiobook')
    end

    def computer_file?
      record.leader[6..7].match?(/m$/)
    end

    def juvenile?
      subjects.any? { |subject| subject.downcase =~ /juvenile/ }
    end

    def published_in_us_uk_or_canada?
      publication_location = record['008'].value[15..17].strip
      return true if us_uk_canada_country_codes.include?(publication_location)
    end

    def within_last_two_years?
      pub_date = record['008'].value[7..10].to_i
      pub_date >= Time.zone.now.year - 2
    end

    def scrub_string(string)
      string.gsub(%r{[.,:/=]}, '')
    end

    # Country codes for all US, UK, and Canada states/provinces
    def us_uk_canada_country_codes
      %w[enk aku alu cau xxu aru azu xxc cou ctu dcu deu flu gau
         hiu iau idu ilu inu ksu kyu lau mau mdu meu miu mnu mou
         msu mtu nbu ncu ndu nhu nju nmu nvu nyu ohu oku oru pau
         riu scu sdu tnu txu utu vau vtu wau wiu wvu wyu abc bcc
         mbc nfc nkc nsc ntc nuc onc quc snc xxk wlk stk]
    end
  end
end
# rubocop:enable Metrics/ClassLength
