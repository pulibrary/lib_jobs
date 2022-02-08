# frozen_string_literal: true
require "sidekiq/web"
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_sets#index'

  resources :data_sets
  get '/data_sets/latest/:category', to: 'data_sets#latest', defaults: { format: 'text' }

  get '/staff-directory', to: 'staff_directory#index', defaults: { format: 'csv' }
  get '/removed-staff', to: 'staff_directory#removed', defaults: { format: 'text' }

  post '/ncip-renew', to: 'renew#index', defaults: { format: 'xml' }

  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
end
