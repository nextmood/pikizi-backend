# - A Filter  (this is an abstract class)
#
class ProductFilter < ActiveRecord::Base
  
  belongs_to :choice
  belongs_to :product
  belongs_to :feature
  
  def as_string() "??" end
  def as_extract() as_string end
    
  # litte helper
  def self.range_include(value, descriptor)
    if value.is_a?(Array)
      value.any? { |v| range_include(v, descriptor) }
    else
      raise "error" unless DomainNumeric.is_a_float(value)
      min_value = DomainNumeric.is_a_float(descriptor[:min])
      max_value = DomainNumeric.is_a_float(descriptor[:max])
      (min_value.nil? or value >= min_value) and (max_value.nil? or value <= max_value) 
    end
  end
  
end

# FilterProduct
class ProductFilterSimple < ProductFilter
  

  # create a new ProductFilterSimp-le based on a product
  def self.create_from_product(product, recommendation)
    ProductFilterSimple.create(:product => product, :recommendation => recommendation)
  end
    
  # return true if a text-string map the regex
  # if the regex is nil, return always true wahtver the value
  def include?(a_product) product == a_product end
  
  
end

# FilterProduct
class ProductFilterRating < ProductFilter
  
  

  # create a new ProductFilterSimp-le based on a product
  def self.create_from_rating(feature, recommendation)
    ProductFilterRating.create(:feature => feature, :recommendation => recommendation)
  end
    
  def as_string() "on rating #{feature.label}" end
  
  def include?(a_product) false end 
    
end

# ProductFilterFeature (this is an abstract class)
class ProductFilterFeature < ProductFilter
  
  serialize :descriptor, Hash
  
  # create a new ProductFilterFeature based on a Feature's domain
  # parameter in descriptor
  # recommendation => +1, if the filter match a product, a positive or negative recomemndation
  def self.create_from_feature(feature, recommendation)
    pf =  if feature.is_a?(FeatureHeader)
            nil
          elsif feature.is_a?(FeatureText)
            ProductFilterFeatureText.new(:descriptor => { :regexp => nil })
          elsif feature.is_a?(FeatureTextArea)
            ProductFilterFeatureText.new(:descriptor => { :regexp => nil })
          elsif feature.is_a?(FeatureNumeric)
            ProductFilterFeatureNumeric.new(:descriptor => { :min => feature.domain.descriptor[:min], :max => feature.domain.descriptor[:max] })
          elsif feature.is_a?(FeatureNumericInterval)
            ProductFilterFeatureNumeric.new(:descriptor => { :min => feature.domain.descriptor[:min], :max => feature.domain.descriptor[:max] })
          elsif feature.is_a?(FeatureDate)
            ProductFilterFeatureDate.new(:descriptor => { :earlier => feature.domain.descriptor[:min], :latest => feature.domain.descriptor[:max] })
          elsif feature.is_a?(FeatureEnumerated)
            ProductFilterFeatureTags.new(:descriptor => { :tag_ids => [] })
          else
            raise "oups... unknown feature class #{feature.class}"
          end
    pf.feature = feature
    pf.recommendation = recommendation
    pf.save
    pf
  end
  
    
  # create a list of ProductFilter matching the differnet value of a feature
  # recommendation => +1, if the filter match a product, a positive or negative recomemndation
  def self.create_split_from_feature(feature, recommendation)
    product_filters = if feature.is_a?(FeatureHeader) or feature.is_a?(FeatureText) or feature.is_a?(FeatureTextArea)
                        []
                      elsif feature.is_a?(FeatureNumeric) or feature.is_a?(FeatureNumericInterval)
                        # create 3 intervals
                        min = DomainNumeric.is_a_float(feature.domain.descriptor[:min])
                        max = DomainNumeric.is_a_float(feature.domain.descriptor[:max])
                        delta = (max - min) / 3.0
                        i1 = min + delta
                        i2 = i1 + delta
                        [
                          ProductFilterFeatureNumeric.new(:descriptor => { :min => min, :max => i1 }),
                          ProductFilterFeatureNumeric.new(:descriptor => { :min => i1, :max => i2 }),
                          ProductFilterFeatureNumeric.new(:descriptor => { :min => i2, :max => max }),
                        ]
                      elsif feature.is_a?(FeatureDate)
                        # create 3 intervals
                        earlier = feature.domain.descriptor[:min]
                        latest = feature.domain.descriptor[:max]
                        delta = (latest - earlier) / 3.0
                        i1 = earlier + delta
                        i2 = i1 + delta
                        [
                          ProductFilterFeatureDate.new(:descriptor => { :earlier => earlier, :latest => i1 }),
                          ProductFilterFeatureDate.new(:descriptor => { :earlier => i1, :latest => i2 }),
                          ProductFilterFeatureDate.new(:descriptor => { :earlier => i2, :latest => latest })
                        ]
                      elsif feature.is_a?(FeatureEnumerated)
                        feature.domain.descriptor[:tag_ids].collect { |tag_id| 
                          product_filter = ProductFilterFeature.create_from_feature(feature, recommendation)
                          product_filter.update_definition(:tag_ids => [tag_id])
                          product_filter
                        }
                      else
                        raise "oups... unknown feature class #{feature.class}"
                      end
    product_filters.each { |product_filter|
      product_filter.feature = feature
      product_filter.recommendation = recommendation
      product_filter.save
    }
    product_filters
  end
    
  def update_definition(definition={})
    update_attribute(:descriptor, definition)
  end
  
end

# ProductFilterFeature a text (string) from a regular expression
class ProductFilterFeatureText < ProductFilterFeature
  
  # return true if a text-string map the regex
  # if the regex is nil, return always true wahtver the value
  def include?(product) 
    value_string = product.get_feature_value_genuine(feature_id)
    descriptor[:regexp].nil? or value_string =~ descriptor[:regexp]
  end
  
end


# ProductFilterFeature a Number
# - between min and max
class ProductFilterFeatureNumeric < ProductFilterFeature

  # return true if a number is in the interval
  def include?(product) 
    value_number = product.get_feature_value_genuine(feature_id)
    ProductFilter.range_include(value_number, descriptor) if value_number
  end

  def as_string() 
    min = descriptor[:min]
    max = descriptor[:max]
    if feature.domain
      min = feature.domain.as_string(min)
      max = feature.domain.as_string(max)
    end
    "#{min} -- #{max}"
  end
  
  def as_extract() "#{feature.path}=#{as_string}" end
    
end

# ProductFilterFeature a Date
# - between earlier and latest
class ProductFilterFeatureDate < ProductFilterFeature

  # return true if a date is in the interval
  def include?(product) 
    value_date = product.get_feature_value_genuine(feature_id)
    ProductFilter.range_include(value_date, descriptor)
  end

  def as_string() "#{descriptor[:earlier]} -- #{descriptor[:latest]}" end
  def as_extract() "#{feature.path}=#{as_string}" end
    
end

#  ProductFilterFeature a list of tags
class ProductFilterFeatureTags < ProductFilterFeature

  # return true if all tags_ids are present in descriptor
  # return true if []
  def include?(product) 
    feature_value =  product.get_feature_value(feature_id)
    if feature_value
      value_tag_ids = feature_value.value_genuine
      value_tag_ids = [value_tag_ids] unless value_tag_ids.is_a?(Array)
      value_tag_ids.all? { |tag_id| descriptor[:tag_ids].include?(tag_id) } 
    end
  end

  def update_definition(definition={})
    definition[:tag_ids] = [] unless definition[:tag_ids]
    definition[:tag_ids] = definition[:tag_ids].collect { |tag_id|  Integer(tag_id) }
    super(definition)
  end
  
  def as_string() 
    Dtag.find(descriptor[:tag_ids]).collect(&:label).join(', ')
  end
  
  def as_extract() "#{feature.path}=#{as_string}" end
    
end





