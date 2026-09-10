Rails.application.routes.draw do
  # Identidad (Auth::) — rutas planas /login y /logout.
  get "/login", to: "auth/sessions#new", as: :new_session
  post "/login", to: "auth/sessions#create", as: :login
  delete "/logout", to: "auth/sessions#destroy"

  # Walking skeleton: organizaciones de la cuenta autenticada.
  resources :organizations, only: %i[index create] do
    collection { post :switch }
  end

  # CRM interno (Fase 2) — Leads, Contacts, Opportunities, Pipeline Stages.
  namespace :crm do
    resources :leads, only: %i[index show new create edit update destroy] do
      member { post :convert }
    end
    resources :contacts, only: %i[index show new create edit update destroy]
    resources :opportunities, only: %i[index show new create edit update destroy] do
      member { patch :update_stage }
    end
    resources :pipeline_stages, only: %i[index new create edit update destroy] do
      collection { patch :reorder }
    end
  end

  # MFA (01-02): enrollment TOTP y challenge post-password.
  get "/mfa/enrollment", to: "auth/mfa/enrollments#new", as: :mfa_enrollment
  post "/mfa/enrollment", to: "auth/mfa/enrollments#create"
  resource :mfa_challenge, only: %i[new create destroy], controller: "auth/mfa/challenges"

  resources :passwords, param: :token

  # Invitaciones (TEN-11/FR-011): creación admin + aceptación pública.
  post "/organizations/:organization_id/invitations", to: "admin/invitations#create", as: :organization_invitations
  get "/invitations/accept", to: "invitations#new_accept", as: :accept_invitation
  post "/invitations/accept", to: "invitations#create_accept", as: :accept_invitations

  # Impersonación auditada (D-06): iniciar exige re-auth del interno.
  resource :impersonation, only: %i[new create destroy], controller: "admin/impersonations"

  # Recuperación de contraseña (D-05) bajo Auth:: con rutas planas.
  get "/password/forgot", to: "auth/passwords#new_forgot", as: :forgot_password
  post "/password/forgot", to: "auth/passwords#create_forgot"
  get "/password/reset", to: "auth/passwords#new_reset", as: :reset_password
  patch "/password/reset", to: "auth/passwords#update_reset"

  # Salud para balanceadores (200/500 sin autenticar).
  get "up" => "rails/health#show", as: :rails_health_check

  root "organizations#index"
end
