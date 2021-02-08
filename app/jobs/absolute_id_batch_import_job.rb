
class AbsoluteIdBatchImportJob < ApplicationJob
  def perform(batch: csv_rows)

    @csv_rows.each do |row|
      AbsoluteIdImportJob.perform_now(**row.to_h)
    end
  end
end
