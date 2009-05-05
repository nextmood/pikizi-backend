# tutorial on route: http://guides.rails.info/routing_outside_in.html
#
ActionController::Routing::Routes.draw do |map|

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.resources :users, :member => { :thumbnail => :get}

  map.resource :session
  map.connect '/request_new_password', :controller => 'sessions', :action => 'request_new_password', :conditions => { :method => :get }
  map.connect '/send_new_password', :controller => 'sessions', :action => 'send_new_password', :conditions => { :method => :post }
  
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
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  
  # Amazon API and integration
  map.connect '/search_amazon/:category_id', :controller => 'amazon_look_up', :action => 'index', :conditions => { :method => :get }
  map.connect '/search_amazon/:category_id', :controller => 'amazon_look_up', :action => 'search', :conditions => { :method => :post }
  map.connect '/search_amazon/:category_id/:asin', :controller => 'amazon_look_up', :action => 'details', :conditions => { :method => :get }
  map.connect '/create_product_from_amazon/:category_id/:asin', :controller => 'products', :action => 'new_from_amazon', :conditions => { :method => :get }
    
  map.connect '/quiz_1', :controller => 'quizzes', :action => 'quiz_1', :conditions => { :method => :get }
  map.connect '/quiz_1/:product_id', :controller => 'quizzes', :action => 'quiz_1', :conditions => { :method => :get }
  map.connect '/quiz_2', :controller => 'quizzes', :action => 'quiz_2', :conditions => { :method => :get }
  map.connect '/quiz_3', :controller => 'quizzes', :action => 'quiz_3', :conditions => { :method => :get }
  
  map.connect '/questions_for_product/:product_id', :controller => 'questions', :action => 'questions_for_product', :conditions => { :method => :get }
  map.connect '/remove_question_opinion/:question_id/:product_id', :controller => 'questions', :action => 'remove', :conditions => { :method => :get } 
  map.connect '/user_update_review', :controller => 'reviews', :action => 'create_or_update_review', :conditions => { :method => :post }

  # categories  
  map.resources :categories, :member => { :thumbnail => :get, 
                                          :ibackground => :get,
                                          :matrix_products => [:get, :post], 
                                          :add_new_product => :get, 
                                          :features => :get,
                                          :add_new_default_question => :post,
                                          :add_new_default_feature => :post  }, :has_many => :questions, :shallow => true
  map.connect '/create_new_category', :controller => 'categories', :action => 'create_new_category', :conditions => { :method => :post }
  map.connect '/before_create_question/:category_id/:question_type', :controller => 'categories', :action => 'before_create_question', :conditions => { :method => :get }
    
  # questions
  map.resources :questions, :member => { :thumbnail => :get, :ibackground => :get, :preview => :get, :add_choice => :get}
  map.resources :quizzes, :member => { :export2engine => :get, :stats_from_engine => :get}, :has_many => :questions, :shallow => true 
  map.connect "/remove_choice/:choice_id", :controller => "questions", :action => "remove_choice"
  map.connect "/questions/:id/change_state/:state", :controller => "questions", :action => "change_state"
  
  # choices
  map.resources :choices, :member => { :thumbnail => :get, :thumbnail_150 => :get, :add_filter => :post  }
  
  # products (associated with reviews)
  map.resources :products, :member => { :thumbnail => :get, :thumbnail_150 => :get }, :has_many => [:reviews, :questions], :shallow => true
  map.resources :reviews # this is needed for reviews.xml only ! OPTIMIZE

  # features
  map.resources :tags, :member => { :thumbnail => :get }  
  
  
  # features values
  map.resources :feature_values, :member => { :thumbnail => :get, :rate => :post }
  map.connect "feature_value_update_tag/:feature_value_id", :controller => "feature_values", :action => "update_tag_value"
	map.connect "feature_value_update_tag/:feature_value_id/:tag_id", :controller => "feature_values", :action => "update_tag_value"
	map.connect "feature_value_update_tags/:feature_value_id/:tag_id", :controller => "feature_values", :action => "update_tags_value"
	map.connect "update_current_value", :controller => "feature_values", :action => "update_current_value"

  # features reviewss
  map.connect "/set_rating_feature_review/:feature_review_id/:rating", :controller => "reviews", :action => "set_rating_feature_review"
  
  # tags
  map.resources :features, :member => { :thumbnail => :get }

  # fleximage editor
	map.connect 'fleximage_editor/:ar_object_class/:ar_object_id/:display_thumbnail/:display_editor', :controller => 'main', :action => 'fleximage_editor'
  map.connect 'fleximage_upload/:ar_object_class/:ar_object_id/:display_thumbnail', :controller => 'main', :action => 'fleximage_upload'
  map.connect 'image_url_upload/:ar_object_class/:ar_object_id', :controller => 'main', :action => 'image_url_upload'
  map.connect 'media_url_upload/:ar_object_class/:ar_object_id', :controller => 'main', :action => 'media_url_upload'
  
  # Dashbord
  map.connect 'dashboard/category/:dashboard_action', :controller => 'dashboard', :action => 'dashboard_action_with_category', :conditions => { :method => :post }
  map.connect 'dashboard/choose_product_for/:dashboard_action', :controller => 'dashboard', :action => 'choose_product_for'
  map.connect 'dashboard/categories_edition', :controller => 'dashboard', :action => 'categories_edition'
  map.connect 'dashboard/add_sub_category/:parent_category_id', :controller => 'categories', :action => 'add_sub_category'
  map.connect 'dashboard/remove_category/:category_id', :controller => 'categories', :action => 'remove_category'
    
  # edit/create model (list of features for a given category)
  map.connect 'update_feature_header', :controller => 'features', :action => 'update_feature_header', :conditions => { :method => :post }
	map.connect "edit_feature/:feature_id", :controller => "features", :action => "edit_feature"
	map.connect "close_feature/:feature_id", :controller => "features", :action => "close_feature"
	map.connect "destroy_feature/:feature_id", :controller => "features", :action => "destroy_feature"
  
	
	# misc TO DO
  map.connect '/admin', :controller => 'main', :action => 'admin', :conditions => { :method => :get }
  map.connect '/search', :controller => 'main', :action => 'search'
  
  # Install the default routes as the lowest priority.
  map.connect '', :controller => 'main', :action => 'index', :conditions => { :method => :get }
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
