require 'pikizi_lib'
require 'feature_review'

# A Product is attached to a Category
# example "iphone", is authored by a __manufacturer__ and described by:
# * an id (upc?)
# * a label
# * an image
# * a set of FeatureValue objects
# * a redactional text (description field)
# Relation ships
# * belongs_to :author, -> User
#
class Product < ActiveRecord::Base
  
  
  # plugin ajaxful rating
  ajaxful_rateable :stars => 5, :dimensions => [:speed, :beauty, :price]
  
  
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  belongs_to :category
  
  has_many   :reviews, :dependent => :destroy, :order => "updated_at DESC"
  has_many   :tips, :dependent => :destroy, :include => {:choice => :question}, :order => "updated_at DESC"
  
  has_many   :product_similarities, :order => "product_similarities.similarity DESC", :limit => 10  
  has_many   :similar_products,     :through => :product_similarities

  has_many   :feature_values, :class_name => "FeatureValue", :foreign_key => "product_id", :dependent => :destroy
  has_many   :choices, :dependent => :destroy
    
  after_create Proc.new { |p| p.compute_similarities(1) }
  after_destroy Proc.new { |p| p.compute_similarities(-1); ProductSimilarity.delete_all("product_id=#{p.id} OR similar_product_id=#{p.id}") }
  
  # full text search functionalities
  acts_as_ferret :fields => [ :label, :url, :category_path, :description ]
  
  # act as state machine ee rails.aizatto.com/category/plugins/acts_as_state_machine
  acts_as_state_machine :initial => :draft
  
  state :draft
  state :submitted
  state :reviewed
  state :published
  state :trashed
  
  event :submit do transitions(:from => :draft, :to => :submitted) end
  event :review do transitions(:from => :submitted, :to => :reviewed) end
  event :publish do transitions(:from => :reviewed, :to => :published) end  
  event :trash do transitions(:from => [:draft, :submitted, :reviewed, :published], :to => :trashed) end
  event :reset do transitions(:from => [:reviewed, :published], :to => :submitted) end
  
  # see http://github.com/Squeegy/fleximage/tree/master
  acts_as_fleximage do
    image_directory 'uploaded_photos/product'
    require_image false
    default_image_path "public/images/default/default_product.png" 
  end
  
  
  # validation rules
  RE_URL_OK     = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  MSG_URL_BAD   = "should look like an url address. (example: http://www.domain.com ...)"
          
  validates_presence_of     :label
  validates_length_of       :label, :within => 5..255
  validates_format_of       :url,    :with => RE_URL_OK, :message => MSG_URL_BAD, :allow_nil => true
    
  # initialize a FeatureValue for this product
  def feature_value_initialize(feature, author)
    self.feature_values.create(
      :product_id => self.id, 
      :author_id => author.id , 
      :feature_id => feature.id,
      :value => FeatureValue.convert_for_serialisation(feature.default_feature_value))
  end
  
  # return the FeatureValue object for this Product
  # let's try to keep it the only way to access the FeatureValue object
  # feature_id is either an integer (feature_id) or a string (feature_path) or a feature
  def get_feature_value_genuine(feature_id) get_feature_value(feature_id).value_genuine end
  def get_feature_value_string(feature_id) 
    fv = get_feature_value(feature_id)
    fv ? fv.value_as_string : '??'
  end
  def get_feature_value(feature_id)
  	if feature_id.is_a?(Integer)
  		FeatureValue.find(:first, :conditions => ["feature_values.product_id=? AND feature_values.feature_id=?", id, feature_id])
  	elsif feature_id.is_a?(Feature)
  		get_feature_value(feature_id.id)
  	elsif feature_id.is_a?(String)
  	  raise "error should not be a string #{feature_id}"
  		Feature.get_node_from_path(feature_id, true, :include => :feature_values, 
  			:conditions => "features.category_id IN (#{category.self_and_ancestors.collect(&:id).join(',')}) AND feature_values.product_id=#{id}").feature_values.first
  	else 
  		raise "unknown type for #{feature_id.inspect}"
  	end
  end
  
  # return a list of features roots for this product and the associated feature value
  def get_feature_values_roots()
    @trees ||= self.category.self_and_ancestors.collect { |cat| [cat, Feature.node_roots(:include => :feature_values, :conditions => ["features.category_id=? AND feature_values.product_id =?", cat.id, id])] }
  end
  
  def reset_caches() @trees = nil end
      
  # set the value of a given feature for this product
  # let's try to keep it the only way to set the FeatureValue object
  def set_value(feature_id, value, extract = "", author=nil) 
    feature_value = get_feature_value(feature_id)    
    feature_value.set_value(value, self, extract, author)
  end
  
  def set_values(hash, extract = "", author=nil)
    hash.each { |feature_id, value| set_value(feature_id, value, extract, author) }
  end
  
  # Compute product similarities  
  # this method and all below, should be externalize...
  # this is call when a new product 
  # create sign = +1
  # update => sign = -1 and sign = + 1 
  # destroy sign = -1
  def compute_similarities(sign, diagonal=true)
      self.add_similarity(self.brothers, sign * 0.5, diagonal) 
      self.add_similarity(self.ancestors, sign * 0.25, diagonal) 
      self.category.parent.children.each { |brother_category|
        self.add_similarity(Product.brothers_bis(brother_category.id), sign * 0.1, diagonal) unless brother_category.id == self.category_id
      } if self.category.parent
  end
  
  # Compute product similarities...
  def add_similarity(product, value, diagonal=true)
    if product.is_a?(Array)
      product.each { |p|  self.add_similarity(p, value, diagonal )}
    else
      product_similarity = ProductSimilarity.find(:first, :conditions => "product_id = #{self.id} AND similar_product_id = #{product.id}")
      product_similarity ||= ProductSimilarity.create(:product_id => self.id, :similar_product_id => product.id, :similarity => 0.0)
      ProductSimilarity.update_all("similarity = similarity + #{value}","id=#{product_similarity.id}")
      product.add_similarity(self, value, false) if diagonal
    end
  end
  
  # Compute product similarities...
  def brothers
    Product.brothers_bis(self.category_id, {:exclude => self})
  end
  
  # Compute product similarities...
  def ancestors
    Product.ancestors_bis(self.category.parent, [])
  end
  
	# create a new review by a User for a Product
	def create_review(author, options)
    raise "oups no author #{author.inspect} for review #{options.inspect}" unless author.id
    options[:author] = author
    options[:author_weight] = author.weight
    options[:product] = self
    options[:rating] ||= 3 
    review = Review.create(options) 
    raise "oups saving review #{options.inspect}" unless review
    # create the feature reviews objects
    default_feature_rating = review.rating >= 4
    feature_values.each { |feature_value|
      FeatureReview.create(
              :feature_value_id => feature_value.id,
              :feature_id => feature_value.feature_id,
              :product_id => self.id,
              :review_id => review.id,
              :rating => 0.0)
        }
    review
  end
  
  def build_reviews_tree() [self, reviews] end
  
  # compute the average rating of all products (or a specific product if any is given as a parameter) 
  # this is a weighted average of the reviews rating on this product
  # also compute the average features_value.average_rating out of the feature_reviews
  def self.compute_rating(product=nil)
    Product.update_all("average_rating = NULL", product ? "id=#{product.id}": nil)
    
    condition_sql = product ? "AND reviews.product_id=#{product.id}": nil
    Product.connection.update("
      UPDATE products,
      (
      SELECT 	reviews.product_id AS the_product_id, 
      		IF ( SUM(reviews.author_weight) != 0.0,
      	     SUM(reviews.rating * reviews.author_weight)  / SUM(reviews.author_weight) ,
      	     NULL) AS the_average_rating 
      FROM reviews
      WHERE reviews.rating IS NOT NULL
      #{condition_sql}
      GROUP BY reviews.product_id
      ) as T
      SET products.average_rating = the_average_rating WHERE products.id=T.the_product_id")
    FeatureValue.compute_rating(product=nil)
  end
                  
  protected
    
  # Compute product similarities...
  def self.brothers_bis(category_id, options = {})
    l = Product.find(:all, :conditions => "category_id=#{category_id}")
    l.delete(options[:exclude]) if options[:exclude]
    l
  end

  # Compute product similarities...
  def self.ancestors_bis(category, results)
    if category
      results.concat(Product.brothers_bis(category.id))
      category_parent = category.parent
      category_parent = nil if category_parent == category
      Product.ancestors_bis(category_parent, results) 
    else
      results
    end
  end
  
end
