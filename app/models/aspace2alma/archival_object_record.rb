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
    # 506 text when there is no access note
    DEFAULT_RESTRICTION = 'Collection is open for research use.'
    # subject types that get a 6xx
    SUBJECT_TERM_TYPES = %w[cultural_context topical geographic genre_form].freeze
    # hosts of VIAF URIs
    VIAF_HOSTS = %w[viaf.org www.viaf.org].freeze

    # 008/18-34 for each format
    TAG008_MATERIAL = {
      'books' => '     |     ||| | ',
      'music' => '|||  |           ',
      'computer_files' => '     |  |        ',
      'visual_materials' => '|||  |         ||',
      'mixed_materials' => '     |           '
    }.freeze

    # leader/06
    TAG008_FORMATS = {
      'a' => 'books', 't' => 'books',
      'i' => 'music',
      'm' => 'computer_files',
      'g' => 'visual_materials', 'k' => 'visual_materials',
      'p' => 'mixed_materials'
    }.freeze

    # the resolved archival object
    attr_reader :json

    # refs to resolve when fetching
    def self.resolves
      %w[subjects linked_agents top_container top_container::container_locations]
    end

    # wrap records in a MARCXML collection
    def self.collection_to_marc(ao_jsons, collection_languages: {})
      records = ao_jsons.map do |ao_json|
        new(ao_json, collection_languages: collection_languages.fetch(ao_json.dig('resource', 'ref'), [])).to_marc
      end

      [Marcxml::COLLECTION_START, records.join("\n"), Marcxml::COLLECTION_END].join("\n")
    end

    # language codes from lang_materials
    def self.language_codes(lang_materials)
      Array(lang_materials).filter_map { |lang_material| lang_material.dig('language_and_script', 'language') }.uniq
    end

    # collection languages are the fallback
    def initialize(json, collection_languages: [])
      @json = json
      @collection_languages = collection_languages
    end

    # build the MARC record
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
              #{tag046}
              #{tag099}
              #{tag1xx_creator}
              #{tag245}
              #{tags300.join(' ')}
              #{tag506}
              #{note_fields(520, 'scopecontent').join(' ')}
              #{note_fields(541, 'acqinfo').join(' ')}
              #{note_fields(544, 'relatedmaterial').join(' ')}
              #{note_fields(545, 'bioghist').join(' ')}
              #{note_fields(583, 'processinfo').join(' ')}
              #{tags6xx_subjects.join(' ')}
              #{tags6xx_7xx_agents.join(' ')}
              #{tag856}
              #{tag982}
            </record>
      RECORD
    end

    private

    # component id
    def ref_id
      json['ref_id']
    end

    # title without markup, else a date
    def title
      remove_tags(json['title']).presence || date_title
    end

    # date text for untitled components
    def date_title
      date = json['dates'].first
      return if date.nil?

      date['expression'].presence || [date['begin'], date['end']].compact_blank.join(' - ')
    end

    # the extents
    def extents
      json['extents']
    end

    # instances other than digital objects
    def physical_instances
      json['instances']&.reject { |instance| instance['instance_type'] == 'digital_object' }
    end

    # 008 date type and years
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

    # year from a date
    def year(date)
      date.to_s[/\A\d{4}/]
    end

    # 008 date 1
    def date1
      parsed_dates[0]
    end

    # 008 date 2
    def date2
      parsed_dates[1]
    end

    # 008/06 date type
    def tag008_date_type
      parsed_dates[2]
    end

    # own languages, else the collection's, else und
    def languages
      @languages ||= self.class.language_codes(json['lang_materials']).presence || @collection_languages.presence || ['und']
    end

    # 008/35-37 language
    def tag008_langcode
      languages.first
    end

    # cleaned notes of a type
    def notes(type)
      json['notes'].select { |note| note['type'] == type }.map { |note| remove_tags(note['subnotes'][0]['content']).squish }
    end

    # linked agents' name data
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
          'identifier' => name['authority_id'],
          'name_order' => name['name_order']
        }
      end
    end

    # use dates, else dates of existence
    def name_dates(agent_record, name)
      date_text(name['use_dates']&.first) || date_text(agent_record['dates_of_existence']&.first)
    end

    # text for a structured date
    def date_text(date)
      return if date.nil?

      if (range = date['structured_date_range'])
        date_span(range['begin_date_expression'], range['end_date_expression']) ||
          date_span(year(range['begin_date_standardized']), year(range['end_date_standardized']))
      elsif (single = date['structured_date_single'])
        single['date_expression'].presence || year(single['date_standardized'])
      end
    end

    # join begin and end
    def date_span(start, finish)
      [start, finish].compact_blank.join('-').presence
    end

    # top containers of physical instances
    def top_containers
      physical_instances&.map do |instance|
        if instance['sub_container']
          instance.dig('sub_container', 'top_container', '_resolved')
        elsif instance['top_container']
          instance.dig('top_container', '_resolved')
        end
      end
    end

    # first container's location code
    def top_container_location_code
      top_containers&.first&.dig('container_locations', 0, '_resolved', 'classification')
    end

    # subjects that get a 6xx
    def subjects
      @subjects ||= json['subjects']
                    .select { |subject| SUBJECT_TERM_TYPES.include?(subject.dig('_resolved', 'terms', 0, 'term_type')) }
                    .map do |subject|
        {
          'type' => subject['_resolved']['terms'][0]['term_type'],
          'source' => subject['_resolved']['source'],
          'terms' => subject['_resolved']['terms']
        }
      end
    end

    # leader/06 from the first physical instance
    def type_of_record
      case physical_instances&.first&.dig('instance_type')
      when 'audio' then 'i'
      when 'books' then 'a'
      when 'computer_disks' then 'm'
      when 'graphic_materials' then 'k'
      when 'microform', 'moving_images' then 'g'
      when 'mixed_materials' then 'p'
      else 't'
      end
    end

    # build the leader
    def leader
      "<leader>00000n#{type_of_record}maa22000002u 4500</leader>"
    end

    # build the 001
    def tag001
      "<controlfield tag='001'>#{ref_id}</controlfield>"
    end

    # build the 003
    def tag003
      "<controlfield tag='003'>PULFA</controlfield>"
    end

    # build the 008
    def tag008
      "<controlfield tag='008'>000000#{tag008_date_type}#{date1}#{date2}xx #{tag008_material}#{tag008_langcode} d</controlfield>"
    end

    # 008/18-34 for the format
    def tag008_material
      TAG008_MATERIAL.fetch(TAG008_FORMATS.fetch(type_of_record))
    end

    # build the 035
    def tag035
      "<datafield ind1=' ' ind2=' ' tag='035'>
            <subfield code='a'>(PULFA)#{ref_id}</subfield>
            </datafield>"
    end

    # build the 040
    def tag040
      '<datafield ind1=" " ind2=" " tag="040">
          <subfield code="a">NjP</subfield>
          <subfield code="b">eng</subfield>
          <subfield code="e">dacs</subfield>
          <subfield code="c">NjP</subfield>
          </datafield>'
    end

    # build the 041
    def tag041
      return if languages == ['und']

      "<datafield ind1=' ' ind2=' ' tag='041'>
              #{languages.map { |language| "<subfield code='a'>#{language}</subfield>" }.join(' ')}
            </datafield>"
    end

    # build the 046
    def tag046
      return unless date1.match?(/\d{4}/)

      end_date = "<subfield code='e'>#{date2}</subfield>" if date2.match?(/\d{4}/)

      "<datafield ind1=' ' ind2=' ' tag='046'>
                <subfield code='a'>#{tag008_date_type}</subfield>
                <subfield code='c'>#{date1}</subfield>
                #{end_date}
              </datafield>"
    end

    # build the 099
    def tag099
      "<datafield ind1=' ' ind2=' ' tag='099'>
            <subfield code = 'a'>#{ref_id}</subfield>
            </datafield>"
    end

    # build the 245
    def tag245
      subfield_f =
        if json['title'].blank?
          nil
        elsif date2.match?(/\d{4}/) && date2 != date1
          "<subfield code = 'f'>#{date1}-#{date2}</subfield>"
        elsif date1.match?(/\d{4}/)
          "<subfield code = 'f'>#{date1}</subfield>"
        elsif json['dates'].any? { |date| date['expression'].to_s.strip.casecmp?('undated') }
          "<subfield code = 'f'>undated</subfield>"
        end

      "<datafield ind1=' ' ind2=' ' tag='245'>
            <subfield code = 'a'>#{xml_escape(title)}</subfield>
            #{subfield_f}
            </datafield>"
    end

    # build a 300 per extent
    def tags300
      extents.map do |extent|
        unit = [extent['extent_type'], ("(#{extent['container_summary']})" if extent['container_summary'].present?)].compact.join(' ')
        physical_details = "<subfield code = 'b'>#{xml_escape(extent['physical_details'])}</subfield>" if extent['physical_details'].present?
        dimensions = "<subfield code = 'c'>#{xml_escape(extent['dimensions'])}</subfield>" if extent['dimensions'].present?

        "<datafield ind1=' ' ind2=' ' tag='300'>
            <subfield code = 'a'>#{xml_escape(extent['number'])}</subfield>
            <subfield code = 'f'>#{xml_escape(unit)}</subfield>
            #{physical_details}
            #{dimensions}
            </datafield>"
      end
    end

    # build the 506
    def tag506
      "<datafield ind1=' ' ind2=' ' tag='506'>
            <subfield code = 'a'>#{xml_escape(notes('accessrestrict').first || DEFAULT_RESTRICTION)}</subfield>
            </datafield>"
    end

    # build a note field per note
    def note_fields(tag, type)
      notes(type).map do |note|
        "<datafield ind1=' ' ind2=' ' tag='#{tag}'>
              <subfield code = 'a'>#{xml_escape(note)}</subfield>
              </datafield>"
      end
    end

    # build the 1xx from the first creator
    def tag1xx_creator
      heading = agent_headings.find { |agent_heading| agent_heading[:role] == 'creator' }
      return if heading.nil?

      "<datafield ind1='#{heading[:name_type]}' ind2=' ' tag='1#{heading[:tag].to_s[1..2]}'>
                    <subfield code = 'a'>#{heading[:name]}</subfield>
                    #{heading[:dates]}
                    #{heading[:subfield_g]}
                    #{heading[:subfield_e]}
                    #{heading[:subfield_2]}
                    #{heading[:subfield_0]}
                  </datafield>"
    end

    # build a 6xx or 7xx per agent
    def tags6xx_7xx_agents
      agent_headings.map do |heading|
        "<datafield ind1='#{heading[:name_type]}' ind2='#{heading[:tag].to_s[0] == '7' ? ' ' : heading[:source_code]}' tag='#{heading[:tag]}'>
                <subfield code = 'a'>#{heading[:name]}</subfield>
                #{heading[:dates]}
                #{heading[:subfield_g]}
                #{heading[:subfield_e]}
                #{heading[:subfield_2]}
                #{heading[:subfield_0]}
                #{heading[:subfield_5]}
              </datafield>"
      end
    end

    # headings for agents that have a MARC tag
    def agent_headings
      @agent_headings ||= agents.filter_map { |agent| agent_heading(agent) }
    end

    # an agent's tag, indicators and subfields
    def agent_heading(agent)
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
      return if tag.nil?

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

      source_code = %w[lcnaf lcsh viaf].include?(agent['source']) ? 0 : 7

      name =
        if agent['family_name']
          agent['family_name']
        elsif agent['rest_of_name'].nil?
          agent['primary_name']
        else
          "#{agent['primary_name']}, #{agent['rest_of_name']}"
        end
      name_punctuation =
        if agent['name_dates'].present? || agent['qualifier'].present?
          ',' unless name.end_with?(',', '-')
        elsif !/[.,)-]/.match?(name[-1])
          '.'
        end

      subfield_e =
        if agent['relator'].nil?
          nil
        elsif agent['relator'].length == 3
          "<subfield code='4'>#{agent['relator']}</subfield>"
        else
          "<subfield code='e'>#{agent['relator']}</subfield>"
        end

      {
        role: agent['role'],
        tag: tag,
        name_type: name_type,
        source_code: source_code,
        name: "#{xml_escape(name)}#{name_punctuation}",
        dates: ("<subfield code='d'>#{xml_escape(agent['name_dates'])}</subfield>" unless agent['name_dates'].nil?),
        subfield_g: ("<subfield code='g'>#{xml_escape(agent['qualifier'])}</subfield>" if agent['qualifier']),
        subfield_e: subfield_e,
        subfield_2: (source_code == 7 ? "<subfield code = '2'>#{agent['source']}</subfield>" : nil),
        subfield_0: identifier_subfield(agent['identifier'], agent['source']),
        subfield_5: ('<subfield code="5">NjP</subfield>' if agent['source'] == 'local')
      }
    end

    # build a 6xx per subject
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

        segments = subject['terms'][0]['term'].split('--').map(&:strip)
        main_term = segments.first
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
          if subject['terms'].count == 1
            segments.drop(1).map do |segment|
              subfield_code = /^[0-9]{2}/.match?(segment) ? 'y' : 'x'
              "<subfield code = '#{subfield_code}'>#{xml_escape(segment)}</subfield>"
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

    # build the 856
    def tag856
      "<datafield ind1='4' ind2='2' tag='856'>
              <subfield code='z'>Search and Request</subfield>
              <subfield code = 'u'>https://findingaids.princeton.edu/catalog/#{ref_id}</subfield>
              <subfield code='y'>Princeton University Library Finding Aids</subfield>
              </datafield>"
    end

    # build the 982
    def tag982
      return if top_container_location_code.nil?

      "<datafield ind1=' ' ind2=' ' tag='982'><subfield code='c'>#{top_container_location_code}</subfield></datafield>"
    end

    # handle viaf and other authority identifiers
    def identifier_subfield(identifier, source)
      return if identifier.blank?

      if (viaf_id = viaf_number(identifier, source))
        "<subfield code = '1'>http://viaf.org/viaf/#{viaf_id}</subfield>"
      elsif web_uri?(identifier) && !identifier.match?(/viaf/i) && source != 'viaf'
        "<subfield code = '0'>#{xml_escape(identifier.strip)}</subfield>"
      end
    end

    # http or https URI?
    def web_uri?(identifier)
      uri = URI.parse(identifier.strip)
      %w[http https].include?(uri.scheme) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    # VIAF number from an identifier
    def viaf_number(identifier, source)
      bare_number = identifier.strip[/\A\(?viaf\)?[\s:]*(\d+)\z/i, 1]
      bare_number ||= identifier.strip[/\A\d+\z/] if source == 'viaf'
      return bare_number if bare_number

      uri = URI.parse(identifier.strip)
      return unless VIAF_HOSTS.include?(uri.host&.downcase)

      uri.path[%r{\A(?:/[a-z]{2})?/viaf/(\d+)/?\z}, 1]
    rescue URI::InvalidURIError
      nil
    end

    # remove EAD markup
    def remove_tags(text)
      text.to_s.gsub(%r{</?[\D\S]+?>}, '')
    end

    # escape for XML
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
