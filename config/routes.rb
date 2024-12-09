# frozen_string_literal: true

Rails.application.routes.draw do
  get 'judge_dashboard/index'
  get 'bulk_contest_instances/new'
  get 'bulk_contest_instances/create'
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

  get 'judge_dashboard', to: 'judge_dashboard#index'

  resources :judging_rounds, only: [ :show ] do
    member do
      post 'select_entries_for_next_round'
      patch 'complete_round'
    end
  end

  resources :containers do
    resources :contest_descriptions do
      resources :contest_instances do
        resources :entry_rankings, only: [ :create, :update ]
        resources :judging_assignments, only: [ :index, :create, :destroy ] do
          collection do
            post 'create_judge'
          end
        end
        resources :judging_rounds do
          resources :round_judge_assignments
          resources :entry_rankings, only: [ :create, :update ]
        end
      end
      member do
        get 'eligibility_rules'
      end
    end
    resources :bulk_contest_instances, only: [ :new, :create ]
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
  if Rails.env.development? || Rails.env.staging?
    mount LetterOpenerWeb::Engine, at: '/letter_opener'
  end

  # Place this at the very end of the file to catch all undefined routes
  match '*path', to: 'errors#not_found', via: :all, constraints: lambda { |req|
    req.path.exclude?('/rails/active_storage') &&
    req.path.exclude?('/letter_opener')
  }
end
