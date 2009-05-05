class WishlistsController < ApplicationController
  
  # Home page
  def index
    @wishlist = Wishlist.get_current(current_user, session)
  end
  
  # this is a rjs
  def add
    product = Product.find(params[:id])
    wishlist = Wishlist.get_current(current_user, session)
    (wishlist.products << product) unless wishlist.products.include?(product)
    render :update do |page|   
      page.replace_html("current_wish_list",render(:partial => "/wishlists/album", 
                                                      :locals => {:owner => current_user}))
    end
  end
  
  # this is a rjs (POST)
  def search
    list_results = Search.execute(PikiziLib.clean_string(params[:search_text]))
    render :update do |page|   
      page.replace_html("current_wish_list",render(:partial => "/wishlists/search_results", 
                                                      :locals => {:list_results => list_results}))
    end
  end
  
  def show_album
    render :update do |page|   
      page.replace_html("current_wish_list",render(:partial => "/wishlists/album", 
                                                      :locals => {:owner => current_user}))
    end
  end
  
  # this is a rjs
  def remove
    product = Product.find(params[:id])
    wishlist = Wishlist.get_current(current_user, session)
    wishlist.products.delete(product)
    render :update do |page|   
      page.remove("dg_#{product.id}")
    end
  end
  
end
