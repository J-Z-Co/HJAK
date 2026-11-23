Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations", sessions: "users/sessions" }
  root "measurements#new"
  resources :measurements, only: [ :new, :create, :destroy ]
  resources :indices, only: [ :index, :show ], param: :key do
    collection { get :overview }
  end
  get "groups/join", to: "group_joins#new", as: :join_group
  post "groups/join", to: "group_joins#create"
  resources :groups, param: :public_id, only: [ :index, :new, :create, :show, :destroy ] do
    member do
      get :share
      get :year
      post :nudge
    end
    resources :members, param: :user_id, only: [] do
      resources :indices, only: [ :index, :show ], param: :key, module: :members
    end
  end
  delete "groups/:public_id/membership", to: "memberships#destroy", as: :group_membership
  resource :me, only: [ :show, :update ], controller: "profiles"
  resources :suggestions, only: [ :index, :create, :destroy ] do
    member { post :vote }
  end
  resources :corrections, only: [ :index, :show ], param: :metric do
    resources :entries, only: [ :edit, :update, :destroy ], controller: "correction_entries"
  end
  # JSON API for the WeChat mini program (token auth, no cookies/CSRF).
  namespace :api do
    namespace :v1 do
      post "auth/wechat", to: "auth#login"

      get    "measurements/new",  to: "measurements#new"
      post   "measurements",      to: "measurements#create"
      delete "measurements/:id",  to: "measurements#destroy"

      get "indices",          to: "indices#index"
      get "indices/overview", to: "indices#overview"
      get "indices/:key",     to: "indices#show"

      get   "me",  to: "profiles#show"
      patch "me",  to: "profiles#update"
      put   "me",  to: "profiles#update"

      get    "groups",                            to: "groups#index"
      post   "groups",                            to: "groups#create"
      post   "groups/join",                       to: "groups#join"
      get    "groups/:public_id",                 to: "groups#show"
      delete "groups/:public_id",                 to: "groups#destroy"
      get    "groups/:public_id/year",            to: "groups#year"
      post   "groups/:public_id/nudge",           to: "groups#nudge"
      delete "groups/:public_id/membership",      to: "groups#leave"

      delete "groups/:public_id/members/:user_id/membership", to: "groups#remove_member"
      get    "groups/:public_id/members/:user_id/indices",    to: "members/indices#index"
      get    "groups/:public_id/members/:user_id/indices/:key", to: "members/indices#show"

      get    "suggestions",          to: "suggestions#index"
      post   "suggestions",          to: "suggestions#create"
      delete "suggestions/:id",      to: "suggestions#destroy"
      post   "suggestions/:id/vote", to: "suggestions#vote"

      get    "corrections",                      to: "corrections#index"
      get    "corrections/:metric",              to: "corrections#show"
      patch  "corrections/:metric/entries/:id",  to: "correction_entries#update"
      put    "corrections/:metric/entries/:id",  to: "correction_entries#update"
      delete "corrections/:metric/entries/:id",  to: "correction_entries#destroy"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }

  # Defines the root path route ("/")
  # root "posts#index"
end
