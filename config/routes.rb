Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :api, defaults: { format: :json } do
    # Quotes
    get ':symbol/quotes', to: 'quotes#quote'
    get 'quotes', to: 'quotes#quotes'

    # Symbols
    get 'symbols', to: 'symbols#symbols'

    # App Store
    post 'appstore/verify_receipt', to: 'appstore#verify_receipt'
    get 'appstore/ping', to: 'appstore#ping'
  end
end
