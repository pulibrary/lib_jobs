# frozen_string_literal: true
module OpenMarcRecords
  module Actions
    class Download < LibJobsHanami::Action
      include Deps['repos.marc_files']
      include Dry::Monads[:maybe]

      params do
        required(:id).value(:integer)
      end

      def handle(request, response)
        case marc_files.get_file_path(request.params[:id])
        in Some(Pathname => file_path)
          response.headers['Content-Disposition'] = "attachment; filename=\"#{file_path.basename}\"; filename*=UTF-8''#{file_path.basename}"
          # Safety: it is safe to send this file, since the repository confirms that it is
          # an actual file in the configured Marc files directory
          response.unsafe_send_file file_path
        in None()
          response.status = 404
          response.body = 'File not found'
        end
      end
    end
  end
end
