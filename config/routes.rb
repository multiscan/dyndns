Rails.application.routes.draw do
  resources :records

  get '/touch/:name', to: 'records#touch'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "records#index"
end
