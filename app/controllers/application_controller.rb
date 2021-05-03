# frozen_string_literal: true
class ApplicationController < ActionController::Base
  helper_method :application_name, :current_year, :library_header_menu_items

  def application_name
    t(:application_name)
  end

  def current_year
    Time.zone.today.year
  end

  def header_user_menu_item
    if current_user
      {
        name: current_user.email,
        component: current_user.email,
        href: '#',
        children: [
          {
            name: 'Log Out',
            component: 'Log Out',
            href: destroy_user_session_path
          }
        ]
      }
    else
      {
        name: 'Log In',
        component: 'Log In',
        href: new_user_session_path
      }
    end
  end

  def library_header_menu_items
    [
      {
        name: 'Data Sets',
        component: 'Data Sets',
        href: data_sets_path
      },
      {
        name: 'Staff Directory',
        component: 'Staff Directory',
        href: staff_directory_path
      },
      {
        name: 'Absolute IDs',
        component: 'Absolute IDs',
        href: absolute_ids_path
      },
      {
        name: 'Barcodes',
        component: 'Barcodes',
        href: barcodes_path
      },
      header_user_menu_item
    ]
  end

  def library_header_attributes
    {
      'menu-items': header_menu_items
    }
  end

  def current_user
    return super if current_user_params.nil?

    @current_user ||= find_user
  end

  def new_session_path(_scope)
    new_user_session_path
  end

  private

  def current_user_params
    params.permit(user: [:id, :token])[:user]
  end

  def current_user_id
    current_user_params[:id]
  end

  def token_header
    value = request.headers['Authorization']
    return if value.nil?

    value.gsub(/\s*?Bearer\s*/i, '')
  end

  def current_user_token
    token_header || current_user_params[:token]
  end

  def find_user
    User.find_by(id: current_user_id, token: current_user_token)
  end

  def current_client
    @current_client ||= begin
                          source_client = LibJobs::ArchivesSpace::Client.source
                          source_client.login
                          source_client
                        end
  end
end
