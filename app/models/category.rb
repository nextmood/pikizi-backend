
# - describe a hierarchical structure (multiple roots) http://wiki.rubyonrails.org/rails/pages/BetterNestedSet
# - has an image (thumbnail) http://github.com/Squeegy/fleximage/tree/master
# - Product, Question, Feature  objects are attached to one and only one Category
# - Example category CellPhone (sub categories, SmartPhone, MusicPhone, SimplePhone),
# CellPhone.products_all will return all cell phone products in database.
#
class Category < ActiveRecord::Base
 
  require 'domain' # needed for the cosntant DomainEnumerated.standardize_tag
  require 'quiz' # needed for the cosntant DomainEnumerated.standardize_tag
        
  # the 2 following lines setup the Hierarchical structure    
  include Hierarchy
  
  # propagate a label modifications
  def label_edit=(value)
    self.label = value
    Category.rebuild!
    update_path_and_sort
    value
  end
  def label_edit() label end
  
                                            
  # image associated with this category
  acts_as_fleximage do
    image_directory 'uploaded_photos/category'
    require_image false
    default_image_path "public/images/default/default_category.png" 
  end
  
  # default' quizz
  belongs_to :default_quiz, :class_name => "Quiz", :foreign_key => "default_quiz_id"
  has_many :quizzes, :dependent => :destroy
  
  # add a new default category
  def self.add_new_default_category(label, parent_category=nil, author=nil)
    author ||= User.get_user_system
    new_category = Category.create(:label => label, :path => "toto")
    Category.add_node(new_category, parent_category)
    # create the default quizz
    new_category.update_attribute(:default_quiz, Quiz::QuizCategory.create(:category_id => new_category.id, :author => author, :label => "#{label}'s default quizz"))
    new_category
  end
    
  # return all products attached to this category and any sub categories
  def products_all(limit=nil) descendants_linked_objects('products_genuine', limit) end
  has_many :products_genuine, :class_name => "Product", :foreign_key => "category_id"
    
  # return all questions attached to this category and any sub categories
  def questions_all(limit=nil) descendants_linked_objects('questions_genuine', limit) end
  has_many :questions_genuine, :class_name => "Question", :foreign_key => "category_id"

  # list of all features atatched to this category
  has_many :features_genuine, :class_name => "Feature", :foreign_key => "category_id"
  

  
  # return a list of [feature_id, "label"] that can be added to this QuestionGeneric
  def features_availables(current_features = nil, l=[], path = nil, existing_features=nil)
    current_features ||= Feature.node_roots(:conditions => "category_id=#{id}")
    for feature in current_features
      new_path = path ? "#{path}/#{feature.label}" : feature.label
      l << [feature.id, new_path]
      features_availables(feature.node_children, l, new_path, existing_features) if feature.node_children.size > 0
    end
    l
  end
    
  # call back: this is needed to have a clean destroy for hierarhy
  # only call on a leaf
  def on_node_destroy
    products_genuine.each(&:destroy)
    questions_genuine.each(&:destroy)
    features_genuine.each(&:on_node_destroy)
    features_genuine.each(&:destroy)
  end
  
  # add a new Product to this Category
  # create all the FeatureValue objects
  # and return the new product
  def add_new_default_product(label=nil, author=nil)
    author ||= User.get_user_system
    new_product = products_genuine.create(:label => label || "New product", :author_id => author.id)
    new_product.update_attribute(:category_path, path)
    # add  a feature value to to this new product for all features available for this catagory
    self_and_ancestors.each { |category|  
      category.features_genuine.each { |feature| new_product.feature_value_initialize(feature, author)  }
    }
    new_product
  end  
  
  # add a new Feature to this Category
  # and return the new Feature object
  def add_new_default_feature(feature_type, feature_parent_id, label, domain_definition=nil, author = nil)
    author ||= User.get_user_system
    raise "label can't contain character #{Hierarchy.path_separator}" if label.include?(Hierarchy.path_separator)
    feature_parent = nil
    feature_parent = Feature.find(feature_parent_id) if feature_parent_id and feature_parent_id != ""

    
    raise "feature already exists" if Feature.exists?(:category_id => id, :label => label, :parent_id => feature_parent_id)
    new_feature = Feature.create_default(self, feature_type, label, domain_definition, author)
    new_feature.update_attribute(:label, "#{Feature.default_label}_#{new_feature.id}") if new_feature.label == Feature.default_label
    Feature.add_node(new_feature, feature_parent)
    features_genuine << new_feature
    # add  a feature value to all products attached to this category
    products_all.each { |product| product.feature_value_initialize(new_feature, author) }
    new_feature
  end  
    

  
  # add a new Question to this Category
  # and return the new Category object
  def add_new_default_question(question_type, label=nil, author = nil, definition={} )
    author ||= User.get_user_system
    questions_genuine << (new_question = Question.create_default(author, question_type, label, definition))
    raise "error no question" unless new_question
    new_question
  end
  
  # build a tree Category/Product/Review structure  
  def self.build_reviews_tree(tree=nil)
    tree ||= Category.roots
    tree.collect { |category, reviews| 
      reviews = category.products_genuine.collect { |product| product.build_reviews_tree }
      [category, reviews, Category.build_reviews_tree(category.children)] }
  end
        
  def path_without_root() 
    path_as_array = path.split(Hierarchy.path_separator)
    path_as_array.delete_at(0)
    path_as_array.join(Hierarchy.path_separator)
  end
  def path_with_nb_features() "#{path_without_root} (#{features_genuine.size} features)" end
  def path_with_nb_products() "#{path_without_root} (#{products_genuine.size} products)" end
  def path_with_nb_questions() "#{path_without_root} (#{questions_genuine.size} questions)" end

    
end
