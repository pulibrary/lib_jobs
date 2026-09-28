# frozen_string_literal: true
module Aspace2alma
  # A class to construct MarcXML from ASpace archival object records
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Naming/VariableNumber
  class ArchivalObjectRecord
    DEFAULT_RESTRICTION = 'Collection is open for research use.'
    SUBJECT_TERM_TYPES = %w[cultural_context topical geographic genre_form].freeze
    VIAF_HOSTS = %w[viaf.org www.viaf.org].freeze

    TAG008_MATERIAL = {
      'books' => '     |     ||| | ',
      'music' => '|||  |           ',
      'computer_files' => '     |  |        ',
      'visual_materials' => '|||  |         ||'
    }.freeze

    # leader/06
    TAG008_FORMATS = {
      'a' => 'books', 't' => 'books',
      'i' => 'music',
      'm' => 'computer_files',
      'g' => 'visual_materials', 'k' => 'visual_materials'
    }.freeze

    attr_reader :json

    def self.resolves
      %w[subjects linked_agents top_container top_container::container_locations]
    end

    def self.collection_to_marc(ao_jsons)
      records = ao_jsons.map { |ao_json| new(ao_json).to_marc }.join("\n")

      [Marcxml::COLLECTION_START, records, Marcxml::COLLECTION_END].join("\n")
    end

    def initialize(json)
      @json = json
    end

    def to_marc
      <<~RECORD
        <record>
              #{leader}
              #{tag001}
              #{tag003}
              #{tag008}
              #{tag035}
              #{tag040}
              #{tag041}
              #{tag046 || ''}
              #{tag099}
              #{tag1xx_creator || ''}
              #{tag245}
              #{tag300}
              #{tag506}
              #{tags520.join(' ')}
              #{tags541.join(' ')}
              #{tags544.join(' ')}
              #{tags545.join(' ')}
              #{tags583.join(' ')}
              #{tags6xx_subjects.join(' ')}
              #{tags6xx_agents.join(' ')}
              #{tag856}
              #{tag982 || ''}
            </record>
      RECORD
    end

    private

    def ref_id
      json['ref_id']
    end

    def title
      json['title']
    end

    def extents
      json['extents']
    end

    def instances
      json['instances']
    end

    def parsed_dates
      @parsed_dates ||= begin
        dates = json['dates']
        creation_dates = dates.select { |date| date['label'] == 'creation' }
        dates = creation_dates if creation_dates.any?
        non_bulk_dates = dates.reject { |date| date['date_type'] == 'bulk' }
        dates = non_bulk_dates if non_bulk_dates.any?

        begin_years = dates.filter_map { |date| year(date['begin']) }
        end_years = dates.filter_map { |date| year(date['end']) || year(date['begin']) }

        if dates.empty?
          ['    ', '    ', '|']
        elsif begin_years.empty?
          %w[uuuu uuuu n]
        elsif dates.all? { |date| date['date_type'] == 'single' } && begin_years.min == end_years.max
          [begin_years.min, '    ', 's']
        else
          [begin_years.min, end_years.max, 'i']
        end
      end
    end

    def year(date)
      date.to_s[/\A\d{4}/]
    end

    def date1
      parsed_dates[0]
    end

    def date2
      parsed_dates[1]
    end

    def tag008_date_type
      parsed_dates[2]
    end

    def tag008_langcode
      json.dig('lang_materials', 0, 'language_and_script', 'language') || 'eng'
    end

    def notes_of_type(type)
      json['notes'].select { |note| note['type'] == type }
    end

    def cleaned_subnote_content(note)
      remove_tags(note['subnotes'][0]['content'].gsub(/[\r\n]+/, ' '))
    end

    def restriction_notes
      @restriction_notes ||= notes_of_type('accessrestrict').map { |note| cleaned_subnote_content(note) }
    end

    def scope_notes
      @scope_notes ||= notes_of_type('scopecontent').map { |note| cleaned_subnote_content(note) }
    end

    def related_notes
      @related_notes ||= notes_of_type('relatedmaterial').map { |note| cleaned_subnote_content(note) }
    end

    def acq_notes
      @acq_notes ||= notes_of_type('acqinfo').map { |note| cleaned_subnote_content(note) }
    end

    def bioghist_notes
      @bioghist_notes ||= notes_of_type('bioghist').map { |note| cleaned_subnote_content(note) }
    end

    def processinfo_notes
      @processinfo_notes ||= notes_of_type('processinfo').map { |note| cleaned_subnote_content(note) }
    end

    def agents
      @agents ||= json['linked_agents'].map do |agent|
        name = agent['_resolved']['names'][0]
        {
          'role' => agent['role'],
          'relator' => agent['relator'],
          'type' => agent['_resolved']['jsonmodel_type'],
          'source' => name['source'],
          'family_name' => name['family_name'],
          'primary_name' => name['primary_name'],
          'rest_of_name' => name['rest_of_name'],
          'name_dates' => name_dates(agent['_resolved'], name),
          'qualifier' => name['qualifier'],
          'sort_name' => name['sort_name'],
          'identifier' => name['authority_id'],
          'name_order' => name['name_order']
        }
      end
    end

    def name_dates(agent_record, name)
      use_date = name['use_dates'].first
      return use_date.dig('structured_date_range', 'begin_date_expression') if use_date

      existence = agent_record['dates_of_existence']&.first
      return if existence.nil?

      if (range = existence['structured_date_range'])
        start = range['begin_date_expression'] || range['begin_date_standardized']
        finish = range['end_date_expression'] || range['end_date_standardized']
        [start, finish].compact.join('-').presence
      elsif (single = existence['structured_date_single'])
        single['date_expression'] || single['date_standardized']
      end
    end

    def leader_06
      instances&.map do |instance|
        case instance['instance_type']
        when 'audio' then 'i'
        when 'books' then 'a'
        when 'computer_disks' then 'm'
        when 'graphic_materials' then 'k'
        when 'microform', 'moving_images' then 'g'
        else 't'
        end
      end
    end

    def top_containers
      instances&.map do |instance|
        if instance['sub_container']
          instance.dig('sub_container', 'top_container', '_resolved')
        elsif instance['top_container']
          instance.dig('top_container', '_resolved')
        end
      end
    end

    def top_container_location_code
      top_containers&.first&.dig('container_locations', 0, '_resolved', 'classification')
    end

    def subjects
      @subjects ||= json['subjects']
                    .select { |subject| SUBJECT_TERM_TYPES.include?(subject.dig('_resolved', 'terms', 0, 'term_type')) }
                    .map do |subject|
        {
          'type' => subject['_resolved']['terms'][0]['term_type'],
          'source' => subject['_resolved']['source'],
          'full_first_term' => subject['_resolved']['terms'][0]['term'],
          'main_term' => subject['_resolved']['terms'][0]['term'].split('--')[0],
          'terms' => subject['_resolved']['terms']
        }
      end
    end

    def type_of_record
      leader_06&.first || 't'
    end

    def leader
      "<leader>00000n#{type_of_record}maa22000002u 4500</leader>"
    end

    def tag001
      "<controlfield tag='001'>#{ref_id}</controlfield>"
    end

    def tag003
      "<controlfield tag='003'>PULFA</controlfield>"
    end

    def tag008
      @tag008 ||= Nokogiri::XML.fragment(
        "<controlfield tag='008'>000000#{tag008_date_type}#{date1}#{date2}xx #{tag008_material}#{tag008_langcode} d</controlfield>"
      )
    end

    def tag008_material
      TAG008_MATERIAL.fetch(TAG008_FORMATS.fetch(type_of_record))
    end

    def tag035
      "<datafield ind1=' ' ind2=' ' tag='035'>
            <subfield code='a'>(PULFA)#{ref_id}</subfield>
            </datafield>"
    end

    def tag040
      '<datafield ind1=" " ind2=" " tag="040">
          <subfield code="a">NjP</subfield>
          <subfield code="b">eng</subfield>
          <subfield code="e">dacs</subfield>
          <subfield code="c">NjP</subfield>
          </datafield>'
    end

    def tag041
      "<datafield ind1=' ' ind2=' ' tag='041'>
              <subfield code='c'>#{tag008.content[35..37]}</subfield>
            </datafield>"
    end

    def tag046
      return unless date1.match?(/\d{4}/)

      end_date = "<subfield code='e'>#{date2}</subfield>" if date2.match?(/\d{4}/)

      "<datafield ind1=' ' ind2=' ' tag='046'>
                <subfield code='a'>#{tag008_date_type}</subfield>
                <subfield code='c'>#{date1}</subfield>
                #{end_date}
              </datafield>"
    end

    def tag099
      "<datafield ind1=' ' ind2=' ' tag='099'>
            <subfield code = 'a'>#{ref_id}</subfield>
            </datafield>"
    end

    def tag245
      subfield_f =
        if date2.match?(/\d{4}/) && date2 != date1
          "<subfield code = 'f'>#{date1}-#{date2}</subfield>"
        elsif date1.match?(/\d{4}/)
          "<subfield code = 'f'>#{date1}</subfield>"
        end

      "<datafield ind1=' ' ind2=' ' tag='245'>
            <subfield code = 'a'>#{xml_escape(title)}</subfield>
            #{subfield_f || ''}
            </datafield>"
    end

    def tag300
      return '' if extents.empty?

      if extents.count > 1
        repeatable_subfields = extents[1..].map do |extent|
          "<subfield code = 'a'>#{extent['number']}</subfield>
                   <subfield code = 'f'>#{extent['extent_type']})</subfield>"
        end

        Nokogiri::XML.fragment("<datafield ind1=' ' ind2=' ' tag='300'>
            <subfield code = 'a'>#{extents[0]['number']}</subfield>
            <subfield code = 'f'>#{extents[0]['extent_type']} (</subfield>
            #{repeatable_subfields.join(' ')}
          </datafield>")
      else
        Nokogiri::XML.fragment("<datafield ind1=' ' ind2=' ' tag='300'>
            <subfield code = 'a'>#{extents[0]['number']}</subfield>
            <subfield code = 'f'>#{extents[0]['extent_type']}</subfield>
            </datafield>")
      end
    end

    def tag506
      "<datafield ind1=' ' ind2=' ' tag='506'>
            <subfield code = 'a'>#{restriction_notes[0] || DEFAULT_RESTRICTION}</subfield>
            </datafield>"
    end

    def tags520
      scope_notes.map do |scope_note|
        "<datafield ind1=' ' ind2=' ' tag='520'>
              <subfield code = 'a'>#{xml_escape(scope_note)}</subfield>
              </datafield>"
      end
    end

    def tags541
      acq_notes.map do |acq_note|
        "<datafield ind1=' ' ind2=' ' tag='541'>
                <subfield code = 'a'>#{xml_escape(acq_note)}</subfield>
                </datafield>"
      end
    end

    def tags544
      related_notes.map do |related_note|
        "<datafield ind1=' ' ind2=' ' tag='544'>
                <subfield code = 'a'>#{xml_escape(related_note)}</subfield>
                </datafield>"
      end
    end

    def tags545
      bioghist_notes.map do |bioghist_note|
        "<datafield ind1=' ' ind2=' ' tag='545'>
                <subfield code = 'a'>#{xml_escape(bioghist_note)}</subfield>
                </datafield>"
      end
    end

    def tags583
      processinfo_notes.map do |processinfo_note|
        "<datafield ind1=' ' ind2=' ' tag='583'>
                <subfield code = 'a'>#{xml_escape(processinfo_note)}</subfield>
                </datafield>"
      end
    end

    def agent_fields
      @agent_fields ||= begin
        tag1xx = []

        tags6xx_agents = agents.map do |agent|
          tag =
            if (agent['role'] == 'creator' || agent['role'] == 'source') && (agent['type'] == 'agent_person' || agent['type'] == 'agent_family')
              700
            elsif agent['role'] == 'subject' && (agent['type'] == 'agent_person' || agent['type'] == 'agent_family')
              600
            elsif (agent['role'] == 'creator' || agent['role'] == 'source') && agent['type'] == 'agent_corporate_entity'
              710
            elsif agent['role'] == 'subject' && agent['type'] == 'agent_corporate_entity'
              610
            end

          name_type =
            if agent['type'] == 'agent_person'
              1
            elsif agent['type'] == 'agent_family'
              3
            elsif agent['type'] == 'agent_corporate_entity' && agent['name_order'] == 'inverted'
              0
            elsif agent['type'] == 'agent_corporate_entity'
              2
            end

          source_code = %w[lcnaf viaf].include?(agent['source']) ? 0 : 7

          name =
            if agent['family_name']
              agent['family_name']
            elsif agent['rest_of_name'].nil?
              agent['primary_name']
            else
              "#{agent['primary_name']}, #{agent['rest_of_name']}"
            end

          dates = "<subfield code='d'>#{agent['name_dates']}</subfield>" unless agent['name_dates'].nil?
          subfield_e =
            if agent['relator'].nil?
              nil
            elsif agent['relator'].length == 3
              "<subfield code='4'>#{agent['relator']}</subfield>"
            else
              "<subfield code='e'>#{agent['relator']}</subfield>"
            end
          subfield_g = "<subfield code='g'>#{xml_escape(agent['qualifier'])}</subfield>" if agent['qualifier']
          subfield_2 = source_code == 7 ? "<subfield code = '2'>#{agent['source']}</subfield>" : nil
          add_punctuation = agent['name_dates'].nil? && agent['qualifier'].nil? ? '.' : ','
          subfield_0 = identifier_subfield(agent['identifier'], name)
          subfield_5 = '<subfield code="5">NjP</subfield>' if agent['source'] == 'local'

          if agent['role'] == 'creator'
            tag1xx << "<datafield ind1='#{name_type}' ind2=' ' tag='1#{tag.to_s[1..2]}'>
                    <subfield code = 'a'>#{xml_escape(name)}#{add_punctuation unless /[.,)-]/.match?(name[-1])}</subfield>
                    #{dates unless agent['name_dates'].nil?}
                    #{subfield_g}
                    #{subfield_e || ''}
                    #{subfield_2 || ''}
                    #{subfield_0 || ''}
                  </datafield>"
          end

          "<datafield ind1='#{name_type}' ind2='#{tag.to_s[0] == '7' ? ' ' : source_code}' tag='#{tag}'>
                <subfield code = 'a'>#{xml_escape(name)}#{add_punctuation unless /[.,)-]/.match?(name[-1])}</subfield>
                #{dates unless agent['name_dates'].nil?}
                #{subfield_g}
                #{subfield_e || ''}
                #{subfield_2 || ''}
                #{subfield_0 || ''}
                #{subfield_5}
              </datafield>"
        end

        { tag1xx: tag1xx, tags6xx_agents: tags6xx_agents }
      end
    end

    def tag1xx_creator
      agent_fields[:tag1xx][0]
    end

    def tags6xx_agents
      agent_fields[:tags6xx_agents]
    end

    def tags6xx_subjects
      subjects.map do |subject|
        tag =
          case subject['type']
          when 'cultural_context' then 647
          when 'topical', 'temporal' then 650
          when 'geographic' then 651
          when 'genre_form' then 655
          end

        source_code =
          if subject['source'] == 'lcsh' || subject['source'] == 'Library of Congress Subject Headings'
            0
          else
            7
          end

        main_term = subject['main_term']
        subterms = subject['terms'][1..].map do |subterm|
          subfield_code =
            case subterm['term_type']
            when 'temporal', 'style_period', 'cultural_context' then 'y'
            when 'genre_form' then 'v'
            when 'geographic' then 'z'
            else 'x'
            end
          "<subfield code = '#{subfield_code}'>#{xml_escape(subterm['term'].strip)}</subfield>"
        end

        # if there are no subfields but the main term has double dashes, compute subfields
        computed_subterms =
          if subject['terms'].count == 1 && subject['full_first_term'] =~ /--/
            tokens = subject['full_first_term'].split('--')
            tokens.each(&:strip!)
            tokens[1..].map do |token|
              subfield_code = /^[0-9]{2}/.match?(token) ? 'y' : 'x'
              "<subfield code = '#{subfield_code}'>#{xml_escape(token)}</subfield>"
            end
          end

        subfield_2 = source_code == 7 ? "<subfield code = '2'>#{subject['source']}</subfield>" : nil
        subfield_5 = '<subfield code="5">NjP</subfield>' if subject['source'] == 'local'

        "<datafield ind1=' ' ind2='#{source_code}' tag='#{tag}'>
                <subfield code = 'a'>#{xml_escape(main_term)}</subfield>
                  #{subterms.join(' ')}
                  #{computed_subterms&.join(' ')}
                  #{subfield_2}
                  #{subfield_5}
                </datafield>"
      end
    end

    def tag856
      "<datafield ind1='4' ind2='2' tag='856'>
              <subfield code='z'>Search and Request</subfield>
              <subfield code = 'u'>https://findingaids.princeton.edu/catalog/#{ref_id}</subfield>
              <subfield code='y'>Princeton University Library Finding Aids</subfield>
              </datafield>"
    end

    def tag982
      return if top_container_location_code.nil?

      "<datafield ind1=' ' ind2=' ' tag='982'><subfield code='c'>#{top_container_location_code}</subfield></datafield>"
    end

    #handle viaf identifiers
    def identifier_subfield(identifier, name)
      return if identifier.blank?

      if (viaf_id = viaf_number(identifier))
        "<subfield code = '1'>http://viaf.org/viaf/#{viaf_id}</subfield>"
      elsif identifier.match?(/viaf/i)
        Rails.logger.warn("#{self.class}: dropped malformed VIAF identifier '#{identifier}' for #{name} on #{ref_id}")
        nil
      else
        "<subfield code = '0'>#{identifier}</subfield>"
      end
    end

    def viaf_number(identifier)
      bare_number = identifier.strip[/\A\(?viaf\)?[\s:]*(\d+)\z/i, 1]
      return bare_number if bare_number

      uri = URI.parse(identifier.strip)
      return unless VIAF_HOSTS.include?(uri.host&.downcase)

      uri.path[%r{\A/viaf/(\d+)/?\z}, 1]
    rescue URI::InvalidURIError
      nil
    end

    # remove EAD markup
    def remove_tags(text)
      text.to_s.gsub(%r{</?[\D\S]+?>}, '')
    end

    def xml_escape(text)
      encoded = text.to_s.encode(xml: :text)

      # make sure we don't double-encode
      encoded.gsub(/&([a-z]+?);\1;/, '&\1;')
    end
  end
  # rubocop:enable Metrics/ClassLength
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/BlockLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Naming/VariableNumber
end
