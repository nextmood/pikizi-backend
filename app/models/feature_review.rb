# - class to describe the opinion of a blogger about a Product's Feature 
# - no more than one feature review per feature/product/user
# - belongs to a Review
#
# example "the camera sucks"
# * the review id
# * the FeatureValue considered (camera)
# * a rating (-1.0 .. +1.0), in this case "sucks" is translated to -1.0
# * a free text (could be an extract from the review)
# * weight
#
# example "the camera is not as good as the N95's one"
# * the FeatureValue considered (camera)
# * a rating (-1.0 .. +1.0), "is not as good as" is translated to -1.0
# * + the product_id compared (N95)
# 
class FeatureReview < ActiveRecord::Base

  belongs_to :review
  belongs_to :feature
  belongs_to :product
  
  serialize :better_than_product_ids, Array
  serialize :same_product_ids, Array
  serialize :worse_than_product_ids, Array
    
  # return the feature_value associated with this feature_review
  # one could use feature_review.feature_value, but there is a nasty bug
  # see is a rails bug here, see http://dev.rubyonrails.org/ticket/10896
  # only in development mode?
  # belongs_to :feature_value
  def get_feature_value(reload=false)
    unless @feature_value and !reload
      @feature_value = FeatureValue.find(feature_value_id) 
    end
    @feature_value
  end
    
end

