# frozen_string_literal: true
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_sets#index'

  resources :data_sets
  get '/data_sets/latest/:category', to: 'data_sets#latest', defaults: { format: 'text' }

  get '/staff-directory', to: 'staff_directory#index', defaults: { format: 'csv' }
  get '/removed-staff', to: 'staff_directory#removed', defaults: { format: 'text' }

  get '/library-events', to: 'library_events#index', defaults: { format: 'csv' }
  get '/library-databases', to: 'library_databases#index', defaults: { format: 'csv' }

  get '/open-marc-records', to: 'open_marc_records#index'
  get '/open-marc-records/download/:index', to: 'open_marc_records#download'

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
end
