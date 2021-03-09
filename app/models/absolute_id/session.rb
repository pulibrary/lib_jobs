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

  def to_txt
    CSV.generate(col_sep: " | ") do |csv|
      csv << ["ID", "User", "Barcode", "Location", "Container Profile", "Repository", "Call Number", "Box Number"]

      batches.map(&:attributes).each do |batch|
        batch[:tableData].each do |entry|
          location = entry[:location][:value]
          container_profile = entry[:container_profile][:value]
          repository = entry[:repository][:value]
          resource = entry[:resource][:value]
          container = entry[:container][:value]

          csv << [entry[:label], entry[:user], entry[:barcode], location, container_profile, repository, resource, container]
        end
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
