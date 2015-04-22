Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  get '/bill99pay/checkout', :to => "bill99pay#checkout"
  get '/bill99/:id/checkout', :to => "bill99pay#checkout_api"
  post '/bill99/:id/query', :to => "bill99pay#query"
  get '/bill99pay/notify', :to => "bill99pay#notify"
end
