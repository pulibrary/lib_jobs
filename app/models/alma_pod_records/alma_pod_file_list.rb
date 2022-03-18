module AlmaPodRecords
  class AlmaPodFileList

    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.pod_output_path, file_pattern: 'POD.*new_31.tar.gz$', alma_sftp: AlmaSftp.new)
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @sftp_locations = []
    end

    def documents
      @documents ||= download_files
    end
    
    private
    def download_files
      documents = []
      @alma_sftp.start do |sftp|
        sftp.dir.foreach(@input_ftp_base_dir) do |entry|
          next unless /#{@file_pattern}/.match?(entry.name)
          filename = File.join(@input_ftp_base_dir, entry.name)
          data = StringIO.new(sftp.download!(filename))
          documents.concat(Tarball.new(data).contents.map {|data| Nokogiri::XML(data) })
        end
      end
      documents
    end

  end
end