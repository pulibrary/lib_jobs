module Aspace2alma
  # This class is responsible for removing a recently generated aspace2alma file from SFTP.
  # This is useful in cases where there is an existing file on SFTP that Alma has already
  # imported.  Alma imports are not idempotent, so this would lead to duplicate records in
  # Alma!
  # A good example is during Aspace maintenance windows: we will not be able to replace the
  # file on the SFTP server with a fresh file, since we can't get data from Aspace.  In these
  # cases, we will want to run this job instead, to remove the file before Alma processes it
  # a second time.
  class RemoveFileJob < LibJob
    def initialize
      super(category: 'Aspace2alma::RemoveFileJob')
    end

      private

    def handle(data_set:)
      Aspace2almaHelper.remove_file('/alma/aspace/MARC_out.xml')
      data_set.report_time = Time.zone.now
      data_set
    end
  end
end
