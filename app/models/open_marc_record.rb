# frozen_string_literal: true
class OpenMarcRecord
  def self.data_dumps
    Dir.children(LibJobs.config[:open_marc_records_location]).sort_by { |s| s.scan(/\d+/).first.to_i }
  end

  def self.valid?(filename)
    data_dumps.include?(filename)
  end

  def self.file_path(index)
    filename = data_dumps[index.to_i]
    raise ActiveStorage::FileNotFoundError and return unless valid?(filename)
    Rails.root.join(LibJobs.config[:open_marc_records_location], filename)
  end
end
