ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  

  map.resource :session
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.resources     :categories
  {
    :member => {
      :show => [:post, :get],
    }
  }
    
  map.resources     :currencies
  {
    :member => {
      :create_remote => :post
    }
  }
  map.resources     :exchanges

  map.resources     :transfers_items,
    {
    :member => {
      :edit_remote => [:post, :get],
      :discard=> [:post, :get],
      :remove_transfer_item => :get
    }
  }

  map.resources     :transfers,
    {
    :member => {
      :show_details => :post,
      :hide_details => :post
    },
    :collection => {
      :quick_transfer => :post,
    }
  }

  map.resources     :users
  map.resources     :reports
  map.resources     :share_reports, :controller => 'reports'
  map.resources     :value_reports, :controller => 'reports'
  map.resources     :flow_reports, :controller => 'reports'



  map.home          '/', :controller => 'sessions', :action => 'default'

  map.signup '/signup', :controller => 'users', :action => 'new'
  #map.register '/register', :controller => 'users', :action => 'create'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  
  



  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
