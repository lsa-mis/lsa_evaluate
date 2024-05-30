# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' } do
    delete 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root 'static_pages#home'
  resources :static_pages
  resources :editable_contents, only: %i[edit update]

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development? || Rails.env.staging?

  # Place this at the very end of the file to catch all undefined routes
  get '*path', to: 'application#render_404', via: :all
end
