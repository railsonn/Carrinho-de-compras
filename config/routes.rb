require 'sidekiq/web'

Rails.application.routes.draw do
  resources :cart_items
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  get "cart/products" => "products#current_cart_products"
  post "product/create" => "products#create"
  post "cart/create" => "carts#create"
  post "cart" => "products#show_cart"
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
