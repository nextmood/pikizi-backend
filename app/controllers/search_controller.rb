class SearchController < ApplicationController
  
  # Home page
  def index
    search_box_set({})
  end
  
  # Search / Results Page
  # this is a rjs
  def execute
    @mode = params[:mode] #
    
    search_string = PikiziLib.clean_string(params[:search_string])
    category_id = PikiziLib.clean_string(params[:search_in_category_id])
    if search_string or category_id
      products, category = Search.execute(search_string, category_id)
    else
      category = Category.root
    end
    render :update do |page| 
      page.replace("the_search_box", :partial => '/search/formbox', :locals => { :search_string => search_string, :category => category, :products => products })
    end
    
  end
  
  # this is a rjs
  def search_in_category
    products, category = Search.execute("", params[:category_id])
    render :update do |page| 
      page.replace("the_search_box", :partial => '/search/formbox', :locals => { :search_string => "", :category => category, :products => products })
    end
  end
  
  # this is a rjs
  def back_to_search_in_category
    render :update do |page| 
      page.replace("the_search_box", :partial => '/search/formbox', :locals => { :search_string => "", :category => Category.root, :products => nil })
    end
  end
  
  # this is a rjs
  def change_category
    category = Category.find(params[:category_id])
    parent_id = category.parent_id
    render :update do |page| 
      page.replace("line_children_category_#{parent_id}", :partial => '/categories/line_children', :locals => { :parent => category })
    end
  end
  
  # this is a rjs
  def up_one_category
    child_id = params[:child_id]
    parent = Category.find(params[:parent_id])
    render :update do |page| 
      page.replace("line_children_category_#{child_id}", :partial => '/categories/line_children', :locals => { :parent => parent })
    end
  end
  
  # this is a rjs for a product icn select/unselect
  def toggle_product_selection
    product_id = params[:product_id].to_i
    product = Product.find(product_id)
    if search_box_parameters(:product_ids_selected).include?(product_id)
      search_box_parameters(:product_ids_selected).delete(product_id)
    else
      search_box_parameters(:product_ids_selected) << product_id
    end
    render :update do |page| 
      page.replace(product_dom_id(product_id), :partial => '/search/product_result', :locals => { :product => product })
      page.replace("submit_selected_button", :partial => '/search/submit_selected_button')
    end
  end
  
end