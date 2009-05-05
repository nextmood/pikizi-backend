# test
class Wishlist < ActiveRecord::Base
  
  belongs_to  :owner, :class_name => "User", :foreign_key => "owner_id"
  has_many   :collections
  has_many   :products, :through => :collections


  # method xxx
  def self.get_current(user, session)
    if user
      if user.wishlist_current_id
        user.wishlist_current
      else
        wishlist = Wishlist.create(:owner_id => user.id, :label => "#{user.screen_name}'s wishlist")
        user.update_attribute("wishlist_current_id", wishlist.id)
        wishlist
      end
    else
      if wishlist_id = session[:wishlist_id]
        Wishlist.find(wishlist_id)
      else
        wishlist = Wishlist.create(:label => "Default's wishlist")
        session[:wishlist_id] = wishlist.id
        wishlist
      end
    end
  end
  
  def self.product_in?(product, user, session)
    Wishlist.get_current(user, session).products.include?(product)
  end
  
end
