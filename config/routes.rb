# frozen_string_literal: true
Rails.application.routes.draw do
  root 'data_sets#index'
  resources :data_sets
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/staff-directory', to: 'staff_directory#index', defaults: { format: 'csv' }
  get '/removed-staff', to: 'staff_directory#removed', defaults: { format: 'text' }

  get '/absolute-ids', to: 'absolute_ids#index'
  get '/absolute-ids/:value', to: 'absolute_ids#show'
  post '/absolute-ids', to: 'absolute_ids#create'
end
