# frozen_string_literal: true

module CapybaraDownloadable
  def wait_for_download
    Timeout.timeout(default_timeout) do
      sleep 0.1 until downloaded?
    end
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end

  private

  def default_timeout
    10
  end

  def default_path
    Rails.root.join('tmp', 'downloads')
  end

  def downloads
    Dir[default_path.join('*')]
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def downloading?
    downloads.grep(/\.crdownload$/).any?
  end

  def downloaded?
    !downloading? && downloads.any?
  end
end

RSpec.configure do |config|
  config.include CapybaraDownloadable
end
