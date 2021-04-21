# frozen_string_literal: true
require "sidekiq/web"
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_sets#index'

  resources :data_sets
  get '/data_sets/latest/:category', to: 'data_sets#latest', defaults: { format: 'text' }

  get '/staff-directory', to: 'staff_directory#index', defaults: { format: 'csv' }
  get '/removed-staff', to: 'staff_directory#removed', defaults: { format: 'text' }

  # Barcodes
  get '/barcodes/:value', to: 'barcodes#show'

  ## Sessions
  post '/barcodes/sessions', to: 'barcodes/sessions#create'
  get '/barcodes', to: 'barcodes/sessions#index'
  post '/barcodes/sessions/:session_id/synchronize', to: 'barcodes/sessions#synchronize', as: 'barcodes_synchronize_session'
  get '/barcodes/sessions/:session_id', to: 'barcodes/sessions#show_session', as: 'barcodes_session_id'
  post '/barcodes/sessions', to: 'barcodes/sessions#create'

  # I am not certain that this is needed
  post '/barcodes/sessions/batch', to: 'barcodes/sessions#create_batch'

  # Absolute IDs, and related ArchivesSpace Resources
  post '/absolute-ids/repositories/:repository_id/resources/search', to: 'absolute_ids/repositories/resources#search'
  get '/absolute-ids/repositories/:repository_id/resources/:resource_id', to: 'absolute_ids/repositories/resources#show'
  get '/absolute-ids/repositories/:repository_id/resources', to: 'absolute_ids/repositories/resources#index'

  get '/absolute-ids/repositories/:repository_id/containers', to: 'absolute_ids/repositories/containers#index'

  get '/absolute-ids/repositories/:repository_id', to: 'absolute_ids/repositories#show'
  get '/absolute-ids/repositories', to: 'absolute_ids/repositories#index'

  get '/absolute-ids/container-profiles', to: 'absolute_ids/container_profiles#index'
  get '/absolute-ids/locations', to: 'absolute_ids/locations#index'

  get '/absolute-ids/:value', to: 'absolute_ids#show', as: 'absolute_id'

  # Sessions
  get '/absolute-ids', to: 'absolute_ids/sessions#index'
  post '/absolute-ids/sessions/:session_id/synchronize', to: 'absolute_ids/sessions#synchronize', as: 'absolute_ids_synchronize_session'
  get '/absolute-ids/sessions/:session_id', to: 'absolute_ids/sessions#show_session', as: 'absolute_ids_session_id'
  post '/absolute-ids/sessions', to: 'absolute_ids/sessions#create'

  # I am not certain that this is needed
  post '/absolute-ids/sessions/batch', to: 'absolute_ids/sessions#create_batch'

  # External Services (e. g. the ArchivesSpace API)
  get '/services/archivesspace', to: 'services#show_archivesspace'

  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
end
