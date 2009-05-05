require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  
  def setup
    create_all_datas
  end
  
  def testing_products_genuine
    assert_equal 0, @categories["products"].products_genuine.size
    assert_equal 3, @categories["telephones"].products_genuine.size
    assert_equal 1, @categories["televisions"].products_genuine.size
  end

  def testing_products_all
    assert_equal 4, @categories["products"].products_all.size
  end

  def destroy_everything
    assert Tag.count > 0
    assert Product.count > 0
    assert Domain.count > 0
    assert ProductFilter.count > 0
    assert FeatureValue.count > 0
    assert Feature.count > 0
    assert Category.count > 0
    assert ProductSimilarity.count > 0
    Category.roots.each {|x| x.recursive.destroy }
    assert_equal 0, ProductSimilarity.count
    assert_equal 0, Product.count
    assert_equal 0, Tip.count
    assert_equal 0, Question.count
    assert_equal 0, Choice.count
    assert_equal 0, Tag.count
    assert_equal 0, Domain.count
    assert_equal 0, ProductFilter.count
    assert_equal 0, FeatureValue.count
    assert_equal 0, Feature.count
    assert_equal 0, Category.count
  end
  

end



