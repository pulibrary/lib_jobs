# frozen_string_literal: true
class AbsoluteId::Batch < ApplicationRecord
  class CsvPresenter
    def initialize(model)
      @model = model
    end

    def rows
      @rows ||= begin
                  @model.absolute_ids.map do |absolute_id|
                    row_profile = absolute_id.container_profile.is_a?(Hash) && absolute_id.container_profile.present? ? absolute_id.container_profile_object.name : absolute_id.container_profile
                    row_location = absolute_id.location.is_a?(Hash) && !absolute_id.location_object.empty? ? absolute_id.location_object.area : absolute_id.location
                    row_repository = absolute_id.repository.is_a?(Hash) && absolute_id.repository.present? ? absolute_id.repository_object.name : absolute_id.repository
                    row_resource = absolute_id.resource.is_a?(Hash) && absolute_id.resource.present? ? absolute_id.resource_object.title : absolute_id.resource
                    row_container = absolute_id.container.is_a?(Hash) && absolute_id.container.present? ? absolute_id.container_object.indicator : absolute_id.container

                    CSV::Row.new(
                      AbsoluteId::Session::CsvPresenter.headers,
                      [
                        absolute_id.id,
                        absolute_id.locator,
                        @model.user.email,
                        absolute_id.barcode.value,
                        row_location,
                        row_profile,
                        row_repository,
                        row_resource,
                        row_container,
                        AbsoluteId::UNSYNCHRONIZED,
                        absolute_id.synchronized_at
                      ]
                    )
                  end
                end
    end

    def table
      @table ||= begin
                   CSV::Table.new(rows, headers: AbsoluteId::Session::CsvPresenter.headers)
                 end
    end
  end

  class TablePresenter
    def self.columns
      [
        { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
        { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
        { name: 'location', display_name: 'Location', align: 'left', sortable: false },
        { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: false },
        { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
        { name: 'resource', display_name: 'ASpace Resource', align: 'left', sortable: false },
        { name: 'container', display_name: 'ASpace Container', align: 'left', sortable: false },
        { name: 'user', display_name: 'User', align: 'left', sortable: false },
        { name: 'status', display_name: 'Synchronization', align: 'left', sortable: false, datatype: 'constant' }
      ]
    end

    def initialize(model)
      @model = model
    end

    def rows
      @model.absolute_ids.order(:id).map do |absolute_id|
        {
          label: absolute_id.label,
          barcode: absolute_id.barcode.value,
          location: { link: absolute_id.location_object.uri, value: absolute_id.location_object.building },
          container_profile: { link: absolute_id.container_profile_object.uri, value: absolute_id.container_profile_object.name },
          repository: { link: absolute_id.repository_object.uri, value: absolute_id.repository_object.name },
          resource: { link: absolute_id.resource_object.uri, value: absolute_id.resource_object.title },
          container: { link: absolute_id.container_object.uri, value: absolute_id.container_object.indicator },
          user: @model.user.email,
          status: { value: absolute_id.synchronize_status, color: absolute_id.synchronize_status_color },
          synchronized_at: absolute_id.synchronized_at || 'Never'
        }
      end
    end

    def attributes
      {
        id: @model.id,
        label: @model.label,
        absolute_ids: rows
      }
    end

    delegate :to_json, to: :attributes
  end

  has_many :absolute_ids, foreign_key: "absolute_id_batch_id"
  belongs_to :session, class_name: 'AbsoluteId::Session', foreign_key: "absolute_id_session_id", optional: true
  belongs_to :user, foreign_key: "user_id"

  def self.xml_serializer
    AbsoluteIds::Serializers::BatchXmlSerializer
  end

  # Ensures that the AbIDs are ordered
  def absolute_ids
    super.order(id: :asc)
  end

  def label
    format("Batch %06d", id)
  end

  def barcode_only?
    children = absolute_ids.map(&:barcode_only?)
    children.reduce(&:|)
  end

  def synchronized?
    absolute_ids.map(&:synchronized?).reduce(&:&)
  end

  def synchronizing?
    absolute_ids.map(&:synchronizing?).reduce(&:|)
  end

  def synchronize_status
    values = absolute_ids.map(&:synchronize_status)

    if values.include?(AbsoluteId::SYNCHRONIZE_FAILED)
      AbsoluteId::SYNCHRONIZE_FAILED
    elsif values.include?(AbsoluteId::SYNCHRONIZING)
      AbsoluteId::SYNCHRONIZING
    elsif values.include?(AbsoluteId::NEVER_SYNCHRONIZED)
      AbsoluteId::NEVER_SYNCHRONIZED
    elsif values.include?(AbsoluteId::UNSYNCHRONIZED)
      AbsoluteId::UNSYNCHRONIZED
    else
      AbsoluteId::SYNCHRONIZED
    end
  end

  # @todo Determine whether or not the entries have been deprecated
  # Refactor this
  def report_entries
    @report_entries ||= absolute_ids.map do |absolute_id|
      {
        label: absolute_id.label,
        user: user.email,
        barcode: absolute_id.barcode.value,
        location: absolute_id.location_object,
        container_profile: absolute_id.container_profile_object,
        repository: absolute_id.repository_object,
        resource: absolute_id.resource_object,
        container: absolute_id.container_object,
        status: AbsoluteId::UNSYNCHRONIZED,
        synchronized_at: absolute_id.synchronized_at
      }
    end
  end

  def csv_table
    @csv_table ||= csv_presenter.table
  end
  delegate :to_csv, to: :csv_table

  def data_table
    @data_table ||= table_presenter
  end

  def attributes
    {
      id: id,
      label: label,
      absolute_ids: absolute_ids.map(&:attributes)
    }
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    self.class.xml_serializer.new(self, options).serialize(&block)
  end

  # @todo Determine why this is required
  def as_json(**_args)
    attributes
  end

  private

  def csv_presenter
    @csv_presenter ||= CsvPresenter.new(self)
  end

  def table_presenter
    @table_presenter ||= TablePresenter.new(self)
  end
end
