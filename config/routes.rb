Rails.application.routes.draw do
  # Identidad (Auth::) — rutas planas /login y /logout.
  get "/login", to: "auth/sessions#new", as: :new_session
  post "/login", to: "auth/sessions#create", as: :login
  delete "/logout", to: "auth/sessions#destroy"

  # Walking skeleton: organizaciones de la cuenta autenticada.
  resources :organizations, only: %i[index create]

  resources :passwords, param: :token

  # Salud para balanceadores (200/500 sin autenticar).
  get "up" => "rails/health#show", as: :rails_health_check

  root "organizations#index"
end
