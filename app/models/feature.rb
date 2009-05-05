# Describe a list of features
#
# - a common feature to all Product objects of a given Category (and descendants)
# - a label (could be a path like "camera/nb_pixel")
# - a feature has a Domain, i.e. the possible values of this Feature for a Product. (FeatureBinary, FeatureTag, etc...)
# - a feature has a semantic_category (among "style", "feature", "usage"...)
# - a feature has a weight (how important this Feature is, between 0.0 and 1.0)
# - a feature has many Value objects (1 for each product concerned)
# - a feature has several flags (is_ok_for_filtering, is_mandatory)
# if the attribute_name is ommitted, "general" is used per default

# =Example The CellPhone has a Price
# a FeatureNumeric "price_interval" attached to a Category "All Products"
# * a label (price)
# * a semantic_category (feature)
# * a Domain (DomainNumeric, unit = "$")
#
# =Example The shape factor of the cell phone
# a FeatureTag "shape" attached to a Category "CellPhone" and made of
# * a label ("shape")
# * a category_semantic(design)
# * a domain (DomainTag with the values "candybar", "clamshell", ...)
#
# =Example The CellPhone has a Camera Function
# attribute => camera
# a FeatureBinary "camera" attached to a Category "CellPhone" is made of
# * a label (camera)
# * a semantic_category (feature)
# * a Domain (DomainBinary, the cell phone has or not a camera )
#
# =Example The number of pixel of the camera (if any)
# * a label (camera/nb_pixel)
# * a category_semantic(feature)
# * a domain (DomainNumeric, unit = "mpx")
#
# =Example Misc for the camera (if any)
# a FeatureTags 
# * a label (camera/misc)
# * a category_semantic(feature)
# * a domain (DomainTags with values, "autofocus", "flash", etc...)
#
#
# =An other example, the usage of a smart phone to surf the web
# * label (surf the web)
# * category_semantic (usage)
# * a domain (DomainTags with the values  "sometime", "never", "a lot")
#
# =Notes
# - belongs_to :category
# - has_many :feature_values
# this is an abstract class: see  FeatureText , FeatureNumeric, FeatureDate , FeatureBinary, FeatureTag, FeatureTags
#
class Feature < ActiveRecord::Base
  
  # setup the Hierarchical structure    
  include Hierarchy
  
  SEMANTIC_CATEGORIES = ["feature", "style", "usage"]
  
  belongs_to :category
  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  has_many :feature_values
  has_many :feature_reviews  
  has_many :choices
  
  #TODO should be a has_one association...
  belongs_to :domain
    
  # call back: this is needed to have a clean destroy for hierarhy
  def on_node_destroy
    self.domain.destroy if self.domain
    choices.each(&:destroy)
    feature_values.each(&:destroy)
  end
   
  # Rating management
  
  MAX_AUTOMATIC_STARS = 5
  def compute_automatic_rating_for(feature_value, dynamic=false, reverse=false)
    min, max = dynamic ? compute_min_max_automatic_rating_dynamic : compute_min_max_automatic_rating_static
    ratio = (feature_value - min) / (max - min)
    ratio = 1.0 - ratio if reverse
    ratio * MAX_AUTOMATIC_STARS
  end

  def compute_min_max_automatic_rating(dynamic=false)
    l = []
    if dynamic 
      l = feature_values.collect(&:value_for_automatic_rating)
      l.compact! # remove nil values
    end
    l = compute_min_max_automatic_rating_static if l.min == l.max
    [l.min.to_f, l.max.to_f]
  end

  # subclassed...
  def compute_min_max_automatic_rating_static() nil end


    
  # --------------------------------------------------------------------------------------
  # FPA to add an image for the user
  # see http://github.com/Squeegy/fleximage/tree/master
  # --------------------------------------------------------------------------------------
    
  acts_as_fleximage do
    image_directory 'uploaded_photos/feature'
    require_image false
    default_image_path "public/images/default/default_feature.png" 
  end
  
  def self.default_label() "label for a new feature" end
    
  # list of tupple [feature_type, label]
  def self.collection_4_select
    @@collection_4_select ||= Feature.datas.collect { |hash|  [hash[:feature_type], hash[:label]] }
  end

  # create a new Feature object (of feature_type) with default values...
  def self.create_default(category, feature_type, label=nil, initial_definition=nil, author=nil) 
    data = Feature.datas.detect { |hash| hash[:feature_type] == feature_type }
    raise "no data for feature_type=#{feature_type}" unless data
    new_feature = data[:class_name].create(:label => "temp", :category => category)
    raise "Error #{new_feature}" unless new_feature.id
    new_feature.set_default_values(label) # set the default values (including a domain object)
    new_feature.semantic_category = SEMANTIC_CATEGORIES.first unless new_feature.semantic_category
    new_feature.author = (author || User.get_user_system)
    new_feature.save
    new_feature.domain.update_definition(initial_definition) if new_feature.domain and initial_definition
    new_feature
  end
  
  def self.mytest
    nb_tag = Dtag.count
    nb_tag_ok = 0
    Feature.find(:all).each { |feature|
      if feature.domain.is_a?(DomainEnumerated)
        feature.domain.tag_ids.each { |tag_id|  
          begin
            tag = Dtag.find(tag_id)
            nb_tag_ok += 1
          rescue
            puts "error tag_id #{tag_id} doesn't exist"
          end
          }
      end
    }
    puts "nb_tag=#{nb_tag} / constate #{nb_tag_ok}"
  end
           
  # set the default values (including domain), the first time this 
  # Feature is created  
  def set_default_values(label=nil, domain=nil, semantic_category=nil)
    self.label = label || "default label"
    self.domain = domain
    self.semantic_category = semantic_category
  end
  
  # the default value when a new featurevalue is created
  def default_feature_value() nil end

  # return a string (html) represnetation of this feature
  def definition_as_html() 
    "<b>#{label}</b>&nbsp;#{domain ? domain.definition_as_html : nil}"
  end
  

  
  private

  # list of feature_type, label and classes
  def self.datas 
    @@datas ||= [ {:feature_type => "binary", :label => "Binary", :class_name => FeatureBinary },
                  {:feature_type => "numeric", :label => "Numeric", :class_name => FeatureNumeric },
                  {:feature_type => "numeric_interval", :label => "NumericInterval", :class_name => FeatureNumericInterval },
                  {:feature_type => "tag", :label => "Tag", :class_name => FeatureTag },
                  {:feature_type => "tags", :label => "Multiple tags", :class_name => FeatureTags },
                  {:feature_type => "text", :label => "Text", :class_name => FeatureText },
                  {:feature_type => "textarea", :label => "Text Area", :class_name => FeatureTextArea },
                  {:feature_type => "date", :label => "Date", :class_name => FeatureDate },
                  {:feature_type => "header", :label => "Header", :class_name => FeatureHeader }]
  end
  

  
end

# a Feature Header (no domain, just a title)
class FeatureHeader < Feature
  
  def set_default_values(label) super(label || "default_feature_header", nil) end
     
end

# a Feature with a free text value (one line)
class FeatureText < Feature
  
  def set_default_values(label) super(label || "default_feature_text", Domain.create_default(self, "text")) end
  
end

# a Feature with a free text value (multi lines)
class FeatureTextArea < Feature
  
  def set_default_values(label) super(label || "default_feature_text_area", Domain.create_default(self, "text")) end
        
end

# - a Feature with a numeric Float value
# - there is a DomainNumeric object associated
# - example: the price
class FeatureNumeric < Feature
  
  def set_default_values(label) super(label || "default_feature_numeric", Domain.create_default(self, "numeric")) end
  
  def compute_min_max_automatic_rating_static()
    [descriptor[min].to_f, descriptor[:max].to_f]
  end
    
end

# - a Feature with a numeric Float value
# - there is a DomainNumeric object associated
# - example: the price
class FeatureNumericInterval < Feature
  
  def set_default_values(label) 
  	super(label || "default_feature_numeric_interval", Domain.create_default(self, "numeric", 2))
  end
  
  def default_feature_value() [] end
 
  def compute_min_max_automatic_rating_static()
    [descriptor[min].to_f, descriptor[:max].to_f]
  end
    
end

# a Feature with a Time  objectvalue
class FeatureDate < Feature
  
  def set_default_values(label) super(label || "default_feature_date", Domain.create_default(self, "date")) end

  def compute_min_max_automatic_rating_static()
    [descriptor[min], descriptor[:max]]
  end
    
end


class FeatureEnumerated < Feature
  
      
end


# a binary Feature yes/no
# example cell phone have or not a camera
class FeatureBinary < FeatureEnumerated

  def set_default_values(label) super(label || "default_feature_binary", Domain.create_default(self, "binary")) end

  # from no, -> 0.0 to yes 1.0
  def compute_min_max_automatic_rating_static
    [0.0, 1.0]
  end
    
end

# a Feature with a value among a list of tags (DomainTag)
# example feature camera resolution, 1mpx, 2mpx, 3mpx
class FeatureTag < FeatureEnumerated
  
  def set_default_values(label) super(label || "default_feature_tag", Domain.create_default(self, "tag")) end
  
  # from the first choice (1.0) to the last choice
  # order is based on an index
  def compute_min_max_automatic_rating_static
    [1.0, domain.size.to_f]
  end
    
end

# a Feature with sevral values among a list of tags (DomainTags)
# example usage "surf the web", "sometime", "never", "a lot"
class FeatureTags < FeatureEnumerated
  
  def set_default_values(label) 
  	super(label || "default_feature_tags", Domain.create_default(self, "tag", nil)) 
  end
  
  # the default value when a new featurevalue is created
  def default_feature_value() [] end


  # from 0 tag selected to all tag selected
  def compute_min_max_automatic_rating_static
    [0.0, domain.size.to_f]
  end
    
end




