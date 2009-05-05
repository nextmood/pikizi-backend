module FeatureValuesHelper
  
  
  def feature_value_dom_id(feature_value_id) "feature_value_#{feature_value_id}" end
    
  def feature_value_html(feature_value)
    if feature_value
      "#{feature_value.feature ? feature_value.feature.path : '???'} for #{feature_value.product ? feature_value.product.label : '???'}"
    else
      "no feature"
    end
  end
    
end
