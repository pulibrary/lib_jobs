# frozen_string_literal: true
Rails.application.routes.draw do
  mount Flipflop::Engine => "/features"
  mount HealthMonitor::Engine, at: "/"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'data_sets#index'

  resources :data_sets, only: [:index, :show]
  get '/data_sets/latest/:category', to: 'data_sets#latest', defaults: { format: 'text' }

  get '/pul-staff-report', to: 'staff_directory#pul_staff_report', defaults: { format: 'csv' }

  get '/library-events', to: Hanami.app.slices[:library_events].rack_app, via: :all
  get '/library-databases', to: Hanami.app.slices[:library_databases].rack_app, via: :all

  get '/open-marc-records', to: 'open_marc_records#index'
  get '/open-marc-records/download/:index', to: 'open_marc_records#download'

  get '/status', to: 'recent_job_status#index'

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
end
