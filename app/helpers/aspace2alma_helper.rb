# frozen_string_literal: true

module Aspace2almaHelper
  SFTP_DIR = '/alma/aspace'

  # configure sendoff to alma
  def self.alma_sftp(filename)
    Net::SFTP.start(ENV.fetch('SFTP_HOST', nil), ENV.fetch('SFTP_USERNAME', nil), { password: ENV.fetch('SFTP_PASSWORD', nil) }) do |sftp|
      sftp.upload!(filename, File.join(SFTP_DIR, File.basename(filename)))
    end
  end

  # rename old file
  def self.rotate_file(filename)
    old_filename = "#{File.basename(filename, '.*')}_old#{File.extname(filename)}"
    remove_file(File.join(SFTP_DIR, old_filename))
    rename_file(File.join(SFTP_DIR, filename), File.join(SFTP_DIR, old_filename))
  end

  # rename old files so we never send an outdated file by accident
  def self.rename_file(original_path, new_path)
    Net::SFTP.start(ENV.fetch('SFTP_HOST', nil), ENV.fetch('SFTP_USERNAME', nil), { password: ENV.fetch('SFTP_PASSWORD', nil) }) do |sftp|
      sftp.stat(original_path) do |response|
        sftp.rename!(original_path, new_path) if response.ok?
      end
    end
  end

  # remove files in preparation for renaming
  def self.remove_file(path)
    Net::SFTP.start(ENV.fetch('SFTP_HOST', nil), ENV.fetch('SFTP_USERNAME', nil), { password: ENV.fetch('SFTP_PASSWORD', nil) }) do |sftp|
      sftp.stat(path) do |response|
        sftp.remove!(path) if response.ok?
      end
    end
  end
end
