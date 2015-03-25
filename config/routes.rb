Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  get '/bill99pay/checkout', :to => "bill99pay#checkout"
  get '/bill99pay/notify', :to => "bill99pay#notify"
end
