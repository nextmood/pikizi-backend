require 'test_helper'

class FeatureTest < ActiveSupport::TestCase

  def setup
    create_all_datas
  end

  def testing_adding_a_feature
    x = @categories["products"].products_all.size + FeatureValue.count
    feature = @categories["products"].add_new_default_feature("numeric", nil, "test_numeric")
    assert_not_nil feature
    assert_not_nil feature.domain
    assert_equal x, FeatureValue.count
  end  
  
  def testing_destroying_feature_simple
  	nb_produts = @categories["products"].products_all.size
  	nb_tags_before = Dtag.count
  	nb_feature_values_before = FeatureValue.count
  	
    feature_father = @categories["products"].add_new_default_feature("header", nil, "test_h")
    feature1 = @categories["products"].add_new_default_feature("tags", feature_father.id, "feat_test1", {:set_tags => []})
    feature2 = @categories["products"].add_new_default_feature("tags", feature_father.id, "feat_test2", {:set_tags => []})
    
    nb_feature_values_after = nb_produts * 3 + nb_feature_values_before
  	
    assert_equal nb_feature_values_after, FeatureValue.count
    assert_equal [], @products["iphone"].get_feature_value_genuine(feature1.id)
    assert_equal [], @products["iphone"].get_feature_value_genuine(feature2.id)
    
    @products["iphone"].set_value(feature1.id,["tag1", "tag2","tag3"] )
    @products["iphone"].set_value(feature2.id,["tag3", 'tag11'] )
    nb_tags_after = nb_tags_before + 5
    
    assert_equal nb_tags_after, Dtag.count
    
    feature_father.remove_node
    assert_equal nb_feature_values_before, FeatureValue.count
    assert_equal nb_tags_before, Dtag.count
  end


  
  def testing_values
    
    assert @products["iphone"]
    @categories["products"].add_new_default_feature("text", nil, "test_text")
    
    @products["iphone"].reset_caches
    the_value = "c'est un extrait"
    @products["iphone"].set_value("test_text", the_value)
    assert_equal the_value, @products["iphone"].get_feature_value_genuine("test_text")
    
    the_value = nil
    @products["iphone"].set_value("test_text", the_value)
    assert_nil @products["iphone"].get_feature_value_genuine("test_text")
        
    feature_numeric = @categories["products"].add_new_default_feature("numeric", nil, "test_numeric")
    feature_numeric.domain.update_definition(:min => 1, :max => 5000, :format => "% .1f unit")
    
    @products["iphone"].reset_caches
    the_value = 228
    @products["iphone"].set_value("test_numeric", the_value.to_s)
    assert_equal the_value, @products["iphone"].get_feature_value_genuine("test_numeric")

    @categories["products"].add_new_default_feature("date", nil, "test_date")
    
    @products["iphone"].reset_caches
    the_value = Time.now
    @products["iphone"].set_value("test_date", the_value.to_s)
    assert_in_delta 0.0, the_value - @products["iphone"].get_feature_value_genuine("test_date"), 0.99
    
    @categories["products"].add_new_default_feature("binary", nil, "test_binary")
    
    @products["iphone"].reset_caches
    the_value = DomainBinary.yes
    @products["iphone"].set_value("test_binary", the_value)
    assert_equal DomainBinary.yes, Dtag.find(@products["iphone"].get_feature_value_genuine("test_binary")).label
    
    test_feature = @categories["products"].add_new_default_feature("tag", nil, "test_tag")
    test_feature.domain.update_definition(:set_tags => ["truc1", "truc2", "truc3"])
    @products["iphone"].reset_caches
    
    the_value = "truc2"
    @products["iphone"].set_value("test_tag", the_value)
    
    assert_equal the_value, @products["iphone"].get_feature_value_string("test_tag")
    
    test_feature = @categories["products"].add_new_default_feature("tags", nil, "test_tags", :set_tags => [])
    assert_equal 0, test_feature.domain.tag_ids.size

    test_feature.domain.update_definition(:set_tags => ["truc1", "truc2", "truc3", "truc4"])
    assert_equal 4, test_feature.domain.tag_ids.size

    @products["iphone"].reset_caches
    the_value = ["truc2", "truc3"]
    @products["iphone"].set_value("test_tags", the_value)
    @products["iphone"].reset_caches	
    assert_equal the_value, @products["iphone"].get_feature_value_string("test_tags")
    assert_equal 4, test_feature.domain.tag_ids.size
    the_value = ["truc4","truc2","truc5"]

    @products["iphone"].set_value("test_tags", the_value)
    @products["iphone"].reset_caches
    assert_equal ["truc4","truc2","truc5"], @products["iphone"].get_feature_value_string("test_tags")
    
    assert_equal 5, test_feature.domain(true).tag_ids.size
    
    the_value = ["truc8"]
    @products["iphone"].set_value("test_tags", the_value)
	  @products["iphone"].reset_caches
    assert_equal ["truc8"], @products["iphone"].get_feature_value_string("test_tags")
    
    assert_equal 6, test_feature.domain(true).tag_ids.size    

  end
  
end
