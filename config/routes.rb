# frozen_string_literal: true

Rails.application.routes.draw do
  root 'static_pages#home'

  resources :entries do
    member do
      patch 'soft_delete'
      patch :toggle_disqualified
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' }

  devise_scope :user do
    delete 'sign_out', to: 'users/sessions#destroy'
  end

  resources :containers do
    resources :contest_descriptions do
      collection do
        get 'multiple_instances'
        post 'create_multiple_instances'
      end
      resources :contest_instances, path: 'instances'
      member do
        get 'eligibility_rules'
      end
    end
    collection do
      get 'lookup_user'
    end
    resources :assignments, only: %i[create destroy]
  end

  resources :visibilities
  resources :departments
  resources :roles
  resources :static_pages do
    collection do
      get 'entrant_content'
    end
  end
  resources :editable_contents, only: %i[index edit update]
  resources :categories
  resources :class_levels
  resources :address_types
  resources :campuses
  resources :schools
  resources :addresses
  resources :profiles, only: %i[index show new create edit update destroy]
  resources :user_roles
  get 'applicant_dashboard', to: 'applicant_dashboard#index'
  get '/404', to: 'errors#not_found', as: 'not_found'
  get '/500', to: 'errors#internal_server_error', as: 'internal_server_error'

  mount ActiveStorage::Engine => '/rails/active_storage', as: 'active_storage'
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development? || Rails.env.staging?

  # Place this at the very end of the file to catch all undefined routes
  match '*path', to: 'errors#not_found', via: :all, constraints: lambda { |req|
    req.path.exclude?('/rails/active_storage') &&
    req.path.exclude?('/letter_opener')
  }
end
