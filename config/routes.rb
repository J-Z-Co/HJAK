Rails.application.routes.draw do
  devise_for :users
  root "measurements#new"
  resources :measurements, only: [ :new, :create, :destroy ]
  resources :indices, only: [ :index, :show ], param: :key do
    collection { get :overview }
  end
  get "groups/join", to: "group_joins#new", as: :join_group
  post "groups/join", to: "group_joins#create"
  resources :groups, param: :public_id, only: [ :index, :new, :create, :show, :destroy ] do
    member { get :share }
    resources :members, param: :user_id, only: [] do
      resources :indices, only: [ :index, :show ], param: :key, module: :members
    end
  end
  delete "groups/:public_id/membership", to: "memberships#destroy", as: :group_membership
  resource :me, only: [ :show, :update ], controller: "profiles"
  resources :corrections, only: [ :index, :show ], param: :metric do
    resources :entries, only: [ :edit, :update, :destroy ], controller: "correction_entries"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
