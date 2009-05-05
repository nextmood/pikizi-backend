# example "iphone reviewed by engadget", is authored by a blogger and described by:
# * the product id reviewed
# * the blogger id
# * a rating of the product (1-5 stars)
# * a blog post (url)
# * a summary (free text)
# * a set of FeatureReview objects
class Review < ActiveRecord::Base

  belongs_to :product
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  serialize :amazon_data
  
  # act as state machine ee rails.aizatto.com/category/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :draft
  
  state :draft
  state :to_process
  state :processed 
   
  event :submit_for_processing do
    transitions :from => :draft, :to => :to_process
  end
  
  event :end_of_processing do
    transitions :from => :to_process, :to => :processed
  end
   
  # return a tree of feature review for this product and an author
  def get_feature_reviews_roots
    @trees ||= self.product.category.self_and_ancestors.collect { |cat| [cat, Feature.node_roots(:include => :feature_reviews, :conditions => ["features.category_id=? AND feature_reviews.review_id=?", cat.id, id])] }
  end
  
  # create or update a FeatureReview for this Review and a tupple [Feature, Product]
  # base on the existence of the compare_with_product parameter, will generate and returns either:
  # * a FeatureReview::Simple
  #* a FeatureReview::Compare
  def set_feature_review(feature, product, rating, extract="", compare_with_product = nil, weight = 0.5)
    attributes = { :review_id => self.id,
                   :feature_id => feature.id,
                   :product_id => product.id, 
                   :rating => rating, 
                   :weight => weight,
                   :extract => extract,
                   :feature_value_id => FeatureValue.find(:first, :conditions => ["feature_id=? and product_id=?", feature.id, product.id]).id }
    if compare_with_product
      attributes[:compare_with_product_id] = compare_with_product.id
      FeatureReview::Compare.create(attributes)
    else
      FeatureReview::Simple.create(attributes)
    end

  end

  
  def update_counters(sign = 1)

  end
  
end
