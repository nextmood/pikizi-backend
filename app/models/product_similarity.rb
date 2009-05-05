
class ProductSimilarity < ActiveRecord::Base
    
  belongs_to :product
  belongs_to :similar_product, :class_name => "Product", :foreign_key => "similar_product_id"

end
