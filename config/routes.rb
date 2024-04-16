Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root 'static_pages#home'

  get 'static_pages/home'

  if Rails.env.development? || Rails.env.staging?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Place this at the very end of the file to catch all undefined routes
  get '*path', to: 'application#render_404', via: :all

end
