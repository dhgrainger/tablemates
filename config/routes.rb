Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  # Host-only party management
  resources :events, only: %i[ new create edit update destroy ]

  # The party itself, for the host and for guests
  resources :parties, only: :show do
    resource :rsvp, only: %i[ edit update ]
  end

  # Guest access — no accounts. The invite link is shared; /p/ links are personal.
  get "i/:invite_token", to: "invites#show", as: :invite
  post "i/:invite_token", to: "invites#create"
  get "p/:access_token", to: "guest_sessions#show", as: :guest_access

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
