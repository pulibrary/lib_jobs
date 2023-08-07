# frozen_string_literal: false

module Oclc
  # rubocop:disable Metrics/ClassLength
  class Record
    attr_reader :record
    def initialize(marc_record:)
      @record = marc_record
    end

    def generally_relevant?
      !juvenile? && !audiobook? && !published_in_us_uk_or_canada? && monograph? && within_last_two_years?
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

    def author
      # The first available author field
      auth_field = record.fields(%w[100 110 111]).try(:[], 0)
      return '' if auth_field.blank?

      auth_tag = auth_field.tag
      subf_to_skip = auth_subfields_to_skip(auth_tag)
      subf_to_keep = auth_field.subfields.reject do |subfield|
        subf_to_skip.include?(subfield.code)
      end

      subf_to_keep.map { |field| scrub_string(field.value) }.join(' ')
    end

    def description
      return '' unless record['300']

      record['300'].subfields.map(&:value).join(' ')
    end

    def f008_pub_place
      record['008'].value[15..17].strip
    end

    def format
      record.leader[6..7]
    end

    def isbns
      isbn = []
      record.fields('020').each do |field|
        next unless field['a']

        isbn << StdNum::ISBN.normalize(field.value)
      end
      isbn.uniq.join(' | ')
    end

    def lccns
      lccn = []
      record.fields('010').each do |field|
        next unless field['a']

        lccn << StdNum::LCCN.normalize(field.value)
      end
      lccn.uniq.join(' | ')
    end

    def pub_field
      return record['260'] if record['260']

      record.fields('264').min_by(&:indicator2) if record.fields('264').present?
    end

    def pub_place
      return scrub_string(pub_field['a']) if pub_field.try(:[], 'a').present?
      ''
    end

    def pub_name
      return scrub_string(pub_field['b']) if pub_field.try(:[], 'b').present?
      ''
    end

    def pub_date
      return scrub_string(pub_field['c']) if pub_field.try(:[], 'c').present?
      ''
    end

    def title
      title_string = record['245']['a']
      return '' unless title_string

      scrub_string(title_string)
    end

    def oclc_id
      record['001'].value.strip
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

      # Capture and return beginning letters, match the rest, but discard
      call_number.gsub(/^([A-Z]+)[^A-Z].*$/, '\1')
    end

    # Only the number from the call_number
    # If the call_number only consists of a class, it will return 0.0
    def lc_number
      return unless call_number

      # Ignore starting non-numeric characters, capture all numbers
      # If there's a decimal, capture that and subsequent numbers
      # Match but do not capture the rest
      # This results in only the numeric portions of the call number
      call_number.gsub(/^[^0-9]+([0-9]+)(\.[0-9]+)?[^0-9]?.*$/, '\1\2').to_f
    end

    def languages
      f008_language = record['008'].value[35..37]
      languages = [f008_language]
      languages += f041_languages if f041_languages.present?
      languages.uniq.join(' | ')
    end

    def f041_languages
      return nil unless record['041']

      record.fields('041').map { |field| field.subfields.map(&:value) }.flatten.uniq
    end

    def subjects
      accumulator = []
      subject_fields.each do |field|
        text = ""
        field.subfields.each do |subfield|
          case subfield.code
          when 'v', 'x', 'y', 'z'
            text << " -- " + subfield.value
          when /[a-z]/
            text << " " + subfield.value
          end
        end
        accumulator << scrub_string(text)
      end
      accumulator.flatten.uniq
    end

    def subject_fields
      subject_fields = record.fields('600'..'699').select do |field|
        field.indicator2 == '0' || (field.indicator2 == '7' && %w[lcgft aat].include?(field['2']))
      end
      return [] if subject_fields.empty?

      subject_fields
    end

    def subject_string
      return '' if subjects.empty?
      subjects.join(' | ')
    end

    def audiobook?
      target_fields = record.fields('250'..'259')
      return false if target_fields.empty?

      terms = record.fields('250'..'259').map { |field| field.subfields.map(&:value) }.flatten
      terms.map { |term| scrub_string(term) }.uniq.include?('audiobook')
    end

    def juvenile?
      subjects.any? { |subject| subject.downcase =~ /juvenile/ }
    end

    def monograph?
      record.leader[7] == 'm'
    end

    def published_in_us_uk_or_canada?
      publication_location = record['008'].value[15..17].strip
      return true if us_uk_canada_country_codes.include?(publication_location)

      false
    end

    def within_last_two_years?
      pub_date = record['008'].value[7..10].to_i
      pub_date >= Time.zone.now.year - 2
    end

    private

    def auth_subfields_to_skip(field_tag)
      case field_tag
      when '100', '110'
        %w[0 6 e]
      else
        %w[0 6 j]
      end
    end

    def scrub_string(string)
      return string if string.nil?

      new_string = string.dup
      new_string.strip!
      # Scrub the last character if it ends in punctuation
      new_string[-1] = '' if %r{[.,:/=]}.match?(new_string[-1])
      # Remove beginning or ending spaces
      new_string.strip!
      # If there are two or more spaces, replace with a single space
      new_string.gsub(/(\s){2, }/, '\1')
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
