
module LibJobs
  module ArchivesSpace
    class Configuration < OpenStruct
      def base_uri
        @base_uri ||= URI.build(protocol: protocol, host: host, port: port, path: path)
      end
    end
  end
end
