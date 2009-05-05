# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # default layout
  layout "layout_1_column"
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '274a8a7d089377212e77a6bbd4952d63'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  include AuthenticatedSystem
  
  # for use in all controllers
  # using the search component
  def search_box_set(hash)
    session[:search_box_parameters] = {
      :title_search_box_genuine => "Search a Product or service",
      :title_search_box_results => "Search a Product or service",
      :title_2_search_form_results => "Search again",
      :title_2_search_form_genuine => "Enter your text",
      :title_2_search_categories => "or Browse categories",
      :title_1_search_result => "Your search results",
      :postfix_html_genuine => "",
      :postfix_html_results => "",
      :search_image_link => "/products",
      :search_select_link => nil,
      :search_action_link => nil,
      :product_ids_selected => [],
      :title_process_with_selected => "process with #nb_products products selected"
    }
    hash.each { |key, value|  session[:search_box_parameters][key] = value }
  end
  
  # this method also exist as a search helper
  def search_box_parameters(title_symbol) session[:search_box_parameters][title_symbol] end
  
  def self.engine_connection
    @@from_sql_connection ||= Mysql.real_connect(ENGINE_SQL[0], ENGINE_SQL[1], ENGINE_SQL[2], ENGINE_SQL[3])
  end
    
end
