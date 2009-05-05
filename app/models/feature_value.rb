# - a FeatureValue refers to a Feature, a Product, an author
# - describe the value of a Product for a given Feature. This value should be compatible with the Domain of the Feature.
# - as a weight, (between 0.0 and 1.0) measure how important this Feature is in regard to the product. default to the Feature weight
# =example "the iphone's camera has 2mpx"
# * the id of the product (iphone)
# * a FeatureTag label (camera/nb_pixel)
# * a value, (2mpx, compatible with the Domain of the FeatureTag) 
# 
# * has_many :feature_reviews
class FeatureValue < ActiveRecord::Base
  
  belongs_to :feature
  belongs_to :product
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  has_many :feature_reviews, :dependent => :destroy
  
  serialize :value, Array # an array, value is the first in the array (tails for history)
  
  # plugin ajaxful rating
  ajaxful_rateable :stars => 5, :dimensions => [:user, :automatic, :combined]
  
  def record_rating_by_user(user, stars)
    rate(stars, user, :user_simple)
    update_combined_rating
  end
  
  def update_combined_rating
    rate(rate_average(true, :user) * rate_average(true, :automatic) , @system_user, :combined)
  end    
  
  # --------------------------------------------------------------------------------------
  # FPA to add an image for the user
  # see http://github.com/Squeegy/fleximage/tree/master
  # --------------------------------------------------------------------------------------
    
  acts_as_fleximage do
    image_directory 'uploaded_photos/feature_value'
    require_image false
    default_image_path "public/images/default/default_feature_value.png" 
  end
  
     
  # update a feature value with a raw value
  def set_value(raw_value, product = nil, extract="", author=nil)
    self.value_genuine = raw_value # trigger the method value_genuine=
    self.product = product if product
    self.author = author || User.get_user_system 
    self.extract = extract
    self.save
    self
  end
  
  # convert a raw value to a genuine value
  def value_genuine=(raw_value) 
    domain = self.feature.domain
    new_value = FeatureValue.convert_for_serialisation( domain ? domain.check_value(raw_value) : raw_value) # return either a cleanup value ready for serialization or nil
    raise "not in domain feature=#{feature.label} product=#{product.label} raw=#{raw_value.inspect} value=#{new_value.inspect}" unless new_value
    self.value = new_value 
  end
  
    
=begin
  compute the average rating (of all feature reviews)
  for a product if any is given as a parameter

  UPDATE feature_values SET average_rating = NULL;

  UPDATE feature_values,
  (
  SELECT 	feature_reviews.feature_value_id AS the_feature_value_id, 
  		IF ( SUM(reviews.author_weight) != 0.0,
  	     SUM(feature_reviews.rating * reviews.author_weight)  / SUM(reviews.author_weight) ,
  	     NULL) AS the_average_rating 
  FROM feature_reviews, reviews
  WHERE  feature_reviews.review_id = reviews.id
  AND feature_reviews.rating IS NOT NULL
  AND reviews.product_id = 5
  GROUP BY feature_reviews.feature_value_id
  ) as T
  SET feature_values.average_rating= the_average_rating where feature_values.id=T.the_feature_value_id
=end  
  def self.compute_rating(product=nil)
    condition_sql = product ? "product_id=#{product.id}": nil
    FeatureValue.connection.update("UPDATE feature_values SET average_rating = NULL #{('WHERE ' << condition_sql) if condition_sql}")
    FeatureValue.connection.update("
      UPDATE feature_values,
      (
      SELECT 	feature_reviews.feature_value_id AS the_feature_value_id, 
      		IF ( SUM(reviews.author_weight) != 0.0,
      	     SUM(feature_reviews.rating * reviews.author_weight)  / SUM(reviews.author_weight) ,
      	     NULL) AS the_average_rating 
      FROM feature_reviews, reviews
      WHERE  feature_reviews.review_id = reviews.id
      AND feature_reviews.rating IS NOT NULL
      #{('AND reviews.' << condition_sql << ',') if condition_sql}
      GROUP BY feature_reviews.feature_value_id
      ) as T
      SET feature_values.average_rating = the_average_rating WHERE feature_values.id=T.the_feature_value_id")
  end


  
  def value_as_string() feature.domain ? feature.domain.as_string(value_genuine) : value_genuine end
  
  def value_genuine() self.value.first end
  def self.convert_for_serialisation(x) [x] end
     
  # does the feature value is empty? (no value set yet)
  def is_empty?() value.first end
    
  # default value of weight is 0.5
  def weight() feature.weight end
  
         
end
