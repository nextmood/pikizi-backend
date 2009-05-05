ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def create_users
    unless @users
      @users = {}
      @users["system"] = User.automatic_creation("system", "system@toto.fr", {:weight => 10})
      @users["administrator"] = User.automatic_creation("administrator", "admin@toto.fr", {:weight => 10})
      @users["blogger_1"] = User.automatic_creation("blogger_1", "blogger_1@toto.fr")
      @users["blogger_2"] = User.automatic_creation("blogger_2", "blogger_2@toto.fr")
      @users["blogger_expert"] = User.automatic_creation("blogger_expert", "blogger_expert@toto.fr", {:weight => 5})
      @users["manufacturer"] = User.automatic_creation("manufacturer", "manufacturer@toto.fr")
      
      assert User.get_user_system
    end
  end
  
  def create_categories
    create_users
    unless @categories
      @categories = {}
      @categories["services"] = Category.add_new_default_category("Services")
      @categories["products"] = Category.add_new_default_category("Products")
      @categories["electronics"] = Category.add_new_default_category("Electronic products", @categories["products"])
      @categories["telephones"] = Category.add_new_default_category("Telephones", @categories["products"])
      @categories["televisions"] = Category.add_new_default_category("Televisions", @categories["products"])    
    end
  end
  

  
  def create_features
    create_categories
    unless @features
      @features = {}
      @features["price"] = @categories["products"].add_new_default_feature("numeric_interval", nil, "price")
      @features["brand"] = @categories["products"].add_new_default_feature("tag", nil, "brand")
      
      feature_tip = @categories["telephones"].add_new_default_feature("header", nil, "tips")
      f1 = @categories["telephones"].add_new_default_feature("tags", feature_tip.id, "good_for", {:set_tags => []})
      assert_equal 0, f1.domain(true).tag_ids.size
      f2 = @categories["telephones"].add_new_default_feature("tags", feature_tip.id, "bad_for", {:set_tags => []})
      assert_equal 0, f2.domain(true).tag_ids.size
      
      feature_gps = @features["gps"] = @categories["telephones"].add_new_default_feature("binary", nil, "gps")
      @features["gps_detail"] = @categories["telephones"].add_new_default_feature("tags", feature_gps.id, "detail")
      feature_camera = @features["camera"] = @categories["telephones"].add_new_default_feature("binary", nil, "camera")
      @features["camera_nb_pixel"] = @categories["telephones"].add_new_default_feature("numeric", feature_camera.id, "nb_pixel")
      @features["camera_nb_pixel"].domain.update_definition(:min => 1, :max => 12)
      @yes = DomainBinary.yes
      @no = DomainBinary.no
    end
  end

  def create_products
    create_features
    unless @products
      @products = {}
      assert_equal 0, Product.count
      
      @products["nokia95"] = @categories["telephones"].add_new_default_product("nokia n95", @users["blogger_1"])
      @products["nokia95"].set_value("brand", "Nokia", nil, @users["blogger_1"] ) 
      @products["nokia95"].set_value("price", "410;430.00", nil, @users["blogger_1"]) 
      @products["nokia95"].set_value("gps", @yes, nil, @users["blogger_1"])
      @products["nokia95"].set_value("gps/detail", ["tomtom", "assisted"], nil, @users["blogger_1"])            
      @products["nokia95"].set_value("camera", @yes, nil, @users["blogger_1"])
      @products["nokia95"].set_value("camera/nb_pixel", "2", nil, @users["blogger_1"])
      assert_equal 1, Product.count
      assert_equal 9, Feature.count
      assert_equal 9, FeatureValue.count
       
      @products["iphone"] = @categories["telephones"].add_new_default_product("iphone", @users["blogger_1"])
      @products["iphone"].set_value("brand", "Apple", nil, @users["blogger_1"]) 
      @products["iphone"].set_value("price", "300;380.00", nil, @users["blogger_1"]) 
      @products["iphone"].set_value("gps", @yes, nil, @users["blogger_1"]) 
      @products["iphone"].set_value("gps/detail", ["assisted"], nil, @users["blogger_1"])
      @products["iphone"].set_value("camera", @yes, nil, @users["blogger_1"])
      @products["iphone"].set_value("camera/nb_pixel", "2", nil, @users["blogger_1"])
      assert_equal 2, Product.count
      assert_equal 18, FeatureValue.count
      
      @products["razzor"] = @categories["telephones"].add_new_default_product("razzor", @users["blogger_1"])
      @products["razzor"].set_value("brand", "Motorola", nil, @users["blogger_1"]) 
      @products["razzor"].set_value("price", "210", nil, @users["blogger_1"]) 
      @products["razzor"].set_value("gps", @no, nil, @users["blogger_1"]) 
      @products["razzor"].set_value("camera", @yes, nil, @users["blogger_1"])
      @products["razzor"].set_value("camera/nb_pixel", "2", nil, @users["blogger_1"])
      assert_equal 3, Product.count
      assert_equal 27, FeatureValue.count
      
      @products["philips_lcd55"] = @categories["televisions"].add_new_default_product("Big TV lcd 55", @users["manufacturer"])
      @products["philips_lcd55"].set_value("brand", "Phillips", nil, @users["blogger_1"]) 
      @products["philips_lcd55"].set_value("price", "900;970.00", nil, @users["blogger_1"]) 
      assert_equal 4, Product.count
      assert_equal 29, FeatureValue.count
      
    end
  end
    
  def create_questions
    create_products
    unless @questions
      @questions = {}
      @questions["surf_the_net"]= @categories["telephones"].add_new_default_question("tip", "if you need to surf the net?", @users["blogger_1"],
        :product_id => @products["nokia95"].id, :feature_path => "tips/good_for")
      @questions["need_a_gps"]= @categories["telephones"].add_new_default_question("tip", "if you need a GPS?", @users["blogger_1"],
        :product_id => @products["nokia95"].id, :feature_path => "tips/good_for")
      @questions["sleek_design"]= @categories["products"].add_new_default_question("tip", "if you like sleek_design?", @users["blogger_1"],
        :product_id => @products["nokia95"].id, :feature_path => "tips/good_for")
    end
  end              

  def create_all_datas() create_questions end
  
end
