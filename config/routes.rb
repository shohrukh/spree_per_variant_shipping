Spree::Core::Engine.routes.draw do

  namespace :admin do
    resources :products do
      resources :variant_shipping_rates
    end
  end

end
