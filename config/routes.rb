# frozen_string_literal: true

Rails.application.routes.draw do
  root 'static_pages#home'

  resources :entries
  get 'applicant_dashboard/index'
  resources :testingrsmokes

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' } do
    delete 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  resources :containers do
    resources :contest_descriptions do
      resources :contest_instances, path: 'instances'
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
  resources :statuses
  resources :categories
  # resources :contest_descriptions
  resources :class_levels
  # resources :contest_instances
  resources :address_types
  resources :campuses
  resources :schools
  resources :addresses
  resources :profiles, only: %i[index show new create edit update destroy]
  resources :user_roles
  get 'applicant_dashboard', to: 'applicant_dashboard#index'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development? || Rails.env.staging?

  # Place this at the very end of the file to catch all undefined routes
  get '*path', to: 'application#render404', via: :all
end
=======
>>>>>>> dd7ed69 (edit routes)
