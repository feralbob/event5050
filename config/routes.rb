Rails.application.routes.draw do
  namespace :admin do
      resources :draws
      resources :jurisdictions
      resources :licenses
      resources :org_users
      resources :organizations
      resources :raffles
      resources :tickets
      resources :ticket_purchasers

      root to: "organizations#index"
    end
  devise_for :org_users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Organization routes
  namespace :organization do
    # Onboarding wizard routes
    resources :onboarding, only: [:show, :update], controller: 'onboarding', param: :id do
      collection do
        get '/', to: redirect('/organization/onboarding/org_user_details')
      end
    end
    
    # Dashboard (after onboarding)
    get 'dashboard', to: 'dashboard#index', as: :dashboard
  end

  # Defines the root path route ("/")
  root "pages#home"
end
