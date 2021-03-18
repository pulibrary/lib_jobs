# frozen_string_literal: true

class AbsoluteId::Session < ApplicationRecord
  include ActiveModel::Serializers::JSON
  has_many :batches, class_name: 'AbsoluteId::Batch', foreign_key: 'absolute_id_session_id'
  belongs_to :user, foreign_key: 'user_id'

  def label
    format('Session %d (%s)', id, created_at.strftime('%m/%d/%Y'))
  end

  def synchronized?
    batches.map(&:synchronized?).reduce(&:&)
  end

  def synchronizing?
    batches.map(&:synchronizing?).reduce(&:|)
  end

  def synchronize_status
    values = batches.map(&:synchronize_status)

    if values.include?(AbsoluteId::SYNCHRONIZE_FAILED)
      AbsoluteId::SYNCHRONIZE_FAILED
    elsif values.include?(AbsoluteId::NEVER_SYNCHRONIZED)
      AbsoluteId::NEVER_SYNCHRONIZED
    elsif values.include?(AbsoluteId::UNSYNCHRONIZED)
      AbsoluteId::UNSYNCHRONIZED
    elsif values.include?(AbsoluteId::SYNCHRONIZING)
      AbsoluteId::SYNCHRONIZING
    else
      AbsoluteId::SYNCHRONIZED
    end
  end

  def absolute_ids
    @absolute_ids ||= batches.map(&:absolute_ids).flatten
  end

  def attributes
    {
      batches: batches.to_a.map(&:attributes)
    }
  end

  # @todo Determine why this is needed
  def as_json(_options = nil)
    attributes
  end

  def to_yaml
    YAML.dump(attributes)
  end

  def report_entries
    @report_entries ||= begin
                          values = batches.map(&:report_entries)
                          values.flatten
                        end
  end

  def to_txt
    CSV.generate do |csv|
      csv << ['Box Number', 'abID', 'Barcode']

      report_entries.each do |entry|
        ab_id = entry.label
        container = entry.container.indicator.to_s
        csv << [
          container,
          ab_id,
          entry.barcode
        ]
      end
    end
  end

  def self.xml_serializer
    AbsoluteIds::SessionXmlSerializer
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    self.class.xml_serializer.new(self, options).serialize(&block)
  end
end
