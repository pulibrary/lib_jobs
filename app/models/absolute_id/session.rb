class AbsoluteId::Session < ApplicationRecord
  include ActiveModel::Serializers::JSON
  has_many :batches, class_name: 'AbsoluteId::Batch'
  belongs_to :user

  def label
    format("Session %d (%s)", id, created_at.strftime('%m/%d/%Y'))
  end

  def synchronized?
    batches.map(&:synchronized?).reduce(&:&)
  end

  def synchronizing?
    batches.map(&:synchronizing?).reduce(&:|)
  end

  def absolute_ids
    @absolute_ids ||= batches.map(&:absolute_ids).flatten
  end

  def attributes
    {
      batches: batches.map(&:attributes)
    }
  end

  def as_json(options = nil)
    JSON.generate(attributes)
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
    CSV.generate(col_sep: " | ") do |csv|
      csv << ["ID", "User", "Barcode", "Location", "Container Profile", "Repository", "Call Number", "Box Number"]

      report_entries.each do |entry|

        location = "#{entry.location.building} (#{entry.location.uri})"
        container_profile = "#{entry.container_profile.name} (#{entry.container_profile.uri})"
        repository = "#{entry.repository.name} (#{entry.repository.uri})"
        resource = "#{entry.resource.title} (#{entry.resource.uri})"
        container = "#{entry.container.indicator} (#{entry.container.uri})"

        csv << [
          entry.label,
          entry.user,
          entry.barcode,
          location,
          container_profile,
          repository,
          resource,
          container
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
