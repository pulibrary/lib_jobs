# frozen_string_literal: true
Rails.application.routes.draw do
  root 'data_sets#index'
  resources :data_sets
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/staff-directory', to: 'staff_directory#index', defaults: { format: 'csv' }
  get '/removed-staff', to: 'staff_directory#removed', defaults: { format: 'text' }

  get '/absolute-ids/repositories/:repository_id/resources/:resource_id', to: 'absolute_ids/repositories/resources#show'
  get '/absolute-ids/repositories/:repository_id/resources', to: 'absolute_ids/repositories/resources#index'
  get '/absolute-ids/repositories/:repository_id/containers', to: 'absolute_ids/repositories/containers#index'
  get '/absolute-ids/repositories/:repository_id', to: 'absolute_ids/repositories#show'
  get '/absolute-ids/repositories', to: 'absolute_ids/repositories#index'
  get '/absolute-ids/container-profiles', to: 'absolute_ids/container_profiles#index'
  get '/absolute-ids/locations', to: 'absolute_ids/locations#index'
  get '/absolute-ids/:value', to: 'absolute_ids#show', as: 'absolute_id'
  get '/absolute-ids', to: 'absolute_ids#index'
  post '/absolute-ids/synchronize', to: 'absolute_ids#synchronize'
  post '/absolute-ids/batch', to: 'absolute_ids#create_batch'
  post '/absolute-ids', to: 'absolute_ids#create_batch'

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
end
