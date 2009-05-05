class DashboardController < ApplicationController
  
                                        
  include ActionView::Helpers::SanitizeHelper
  
  in_place_edit_for :category, :label_edit
  
  # Home page
  def index
    @expert_in_category_id = current_user.expert_in_category_id || Category.roots.first
  end
  
  def categories_edition
    @roots_categories = Category.roots
  end

  # his is a POST: /dashboard/category/:dashboard_action
  def dashboard_action_with_category
    category_id = params[:category_id]
    case @dashboard_action = params[:dashboard_action]
      when "features_edition" then redirect_to features_category_path(category_id)
      when "product_creation" 
        if params[:from_amazon].blank?
          redirect_to add_new_product_category_path(category_id)
        else
          redirect_to "/search_amazon/#{category_id}"
        end
      when "matrix_products" then redirect_to matrix_products_category_path(category_id)
      when "questions_edition" then redirect_to category_questions_path(category_id)
    end
  end
  
  def choose_product_for
    dashboard_action = params[:dashboard_action]
    search_box_set({:search_image_link => "/dashboard/#{dashboard_action}",
                    :search_action_link => nil,
                    :search_select_link => nil,
                    :title_search_box_genuine => "select product for #{dashboard_action}",
                    :title_process_with_selected => "{dashboard_action} for this product",
                    :title_search_box_results => "Search results",
                    :title_1_search_result => "",
                    :title_2_search_form_genuine => "Search our catalog",
                    :title_2_search_categories => "select product for #{dashboard_action}",
                    :title_2_search_form_results => "Review your search results or make another search.",
                    :postfix_html_genuine => nil})
  end
  
  def product_edition
    redirect_to edit_product_path(params[:id])
  end
  
  def reviews_edition
    redirect_to product_reviews_path(params[:id])
  end


  
  # =================================================================================
  # Exporting database
  # ---------------------------------------------------------------------------------
  #
  
  def export_db
    root_path = `pwd`
    backup_path = "#{root_path}/public/backups"
    pictures_path = "#{root_path}/uploaded_photos"
    db_name = "pikizi_development"
    full_backup_name = "#{backup_path}/#{db_name}.gzip"
    
    #titi = `rm #{backup_path}/*.zip` # remove existing file if any...
    titi = "no"
    #toto = `mysqldump -u root --no-create-info --complete-insert --skip-extended-insert #{db_name} > #{backup_path}/#{db_name}.sql` # dump database
    
    toto = `ls -la`
    # "" 
    # "gzip #{pictures_path} #{backup_path}/#{db_name}.sql > #{full_backup_name}" # zip photos + database
    flash[:notice] = "exported ... in #{root_path} titi=#{titi} toto=#{toto}" 
    #redirect_to "#{full_backup_name}"
    redirect_to "/dashboard"
  end
  


  
  private
  

  
end
