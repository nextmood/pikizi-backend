require 'set'
require 'amatch' # see http://amatch.rubyforge.org/doc/index.html


# Abstract
# - fields: label, image, 
# - follow a state machine (draft, published_test, published, trashed)
# =Relation ships
# - belongs to an author (User)
# - has_many Choice objects
# - belongs to a Category
#
# :display_background_image
# :display_background_media
# :questions, :display_background_help

class Question < ActiveRecord::Base

  belongs_to :author, :class_name => "User", :foreign_key => "author_id"
  has_many :choices, :dependent => :destroy
  
  belongs_to :category
  
  serialize :weighted_sums
  
  acts_as_taggable
    
  # image associated with this question
  acts_as_fleximage do
    image_directory 'uploaded_photos/question'
    require_image false
    default_image_path "public/images/default/default_question.png" 
  end
          
  # validation rules    
  validates_length_of :label, :within => 10..255, 
      :too_short => "Your question should be described with at least %d characters. Please try again.",
      :too_long => "Your question should be described with at most %d characters. Please try again."
  
  # act as state machine ee rails.aizatto.com/category/plugins/acts_as_state_machine
  # default field is :state
  acts_as_state_machine :initial => :draft
  
  state :draft
  state :published_test
  state :published
  state :trashed
    
  event :test do transitions(:from => [:draft, :published, :trashed], :to => :published_test) end  
  event :test_is_ok do transitions(:from => :published_test, :to => :published) end
  event :test_is_ko do transitions(:from => :published_test, :to => :trashed) end
  event :reset do transitions(:from => [:published_test, :published, :trashed], :to => :draft) end
  event :trash do transitions(:from => [:draft, :published_test, :published], :to => :trashed) end
        
  def get_next_possible_events
    case current_state
      when :draft then [["publish", :test!], ["trash", :trash!] ] 
      when :published_test then [["validate", :test_is_ok!], ["reject", :test_is_ko!]]  
      when :published then [["unpublish", :reset!], ["trash", :trash!] ] 
      when :trashed then [["retrieve", :reset!], ] 
      else
        raise "error"
    end
  end
  
  # this is an abstract method
  # to be overloaded if you need to do something when a question'state change
  def change_state_callback(event_method)  end
  
  # create a new Question object (of question_type) with default values...
  # question_type = ["poll", "feature", "tradeoff", "tip", "feature_value", "generic"]
  # 
  def self.create_default(user, question_type, label = nil, definition={}) 
    label ||= "default's label question"
    data = Question.datas.detect { |hash| hash[:question_type] == question_type }
    new_question = data[:class_name].create(:label => label, :author => user, :extract => "describe your question...")
    raise "error label=#{label}, errors=#{new_question.errors.inspect}" unless new_question.id
    new_question.create_template(definition)
    new_question
  end
  
  # return a Choice object with the matching code
  def get_choice_per_code(code) choices.detect { |choice| choice.code == code } end
  
      
  # return a list of QuestionTip similar
  def find_similar_questions(n=5)
    # find the closest question comparing labels
    closest_questions = Question.find(:all, :conditions => "id != #{self.id}").collect { |question|  
      [question, self.label.pair_distance_similar(question.label)]
    }
    closest_questions.sort! { |t1,t2| t2.last <=> t1.last }
    closest_questions.first(n)
  end
    
  # Extra Choices
  def self.extra_choices() [["0", "no opinion"]]  end
       
  # list of tupple [question_type, label]
  def self.collection_4_select
    @@collection_4_select ||= Question.datas.collect { |hash|  [hash[:question_type], hash[:label]] unless hash[:question_type] == "tip" }.compact
  end
  
  def label_interrogative() "#{label} ?" end


  
  # recompute all valid recommendations for each choice
  # using the product_filter
  def compute_tips
    choices.each { |choice| choice.tips.clear } # remove all existing tips     
    # get all product from the categories
    category.products_all.each { |product|  
      choices.each { |choice| 
        choice.product_filters.each { |product_filter|   
          #puts "compute tips for question #{self.label} / choice=#{choice.label}"
          choice.tips.create(:product => product, :choice => choice, :product_filter_id => product_filter.id, :recommendation => product_filter.recommendation) if product_filter.include?(product)
        }
      }
    }
  end
  
  # add a new choice to a question
  def add_choice(author)
    new_choice = Choice::ChoiceSimple.create(:label => "new choice's label", :extract => "choice's description...", :author => author, :question => self, :product_filters => [])
    choices << new_choice
  end
  
  def class_label  
    selected_hash = Question.datas.detect { |h| self.is_a?(h[:class_name]) }
    selected_hash ? selected_hash[:label] : "???"
  end
  
  def self.stats_from_engine(quiz_engine_id, question_engine_id)
    hash_choice_key_stats = { 0 => {:nb_votes => 0, :choice_key => 0} }
    # get the choices for this questions
    res = ApplicationController.engine_connection.query("
      SELECT choice_key
      FROM choices
      WHERE choices.question_id = '#{question_engine_id}'")
    while row = res.fetch_row do 
      ch_k = Integer(row[0])
      hash_choice_key_stats[ch_k] = {:nb_votes => 0, :choice_key => ch_k}
    end
    
    # get the answers for this quiz and question_engine_id
    res = ApplicationController.engine_connection.query("
      SELECT answers.choice_keys
      FROM answers, quiz_instances
      WHERE quiz_instances.id = answers.quiz_instance_id AND
            quiz_instances.quiz_id = '#{quiz_engine_id}' AND
            answers.question_id = '#{question_engine_id}'")
      while row = res.fetch_row do 
        row[0].split(';').each { |choice_key| 
          hash_choice_key_stats[Integer(choice_key)][:nb_votes] += 1          
           }
      end
      l = hash_choice_key_stats.collect { |ch_k, h| h }.sort! { |h1, h2| h2[:nb_votes] <=> h1[:nb_votes] }
      ranking_index = 0
      l.each { |h|  h[:ranking] = (ranking_index += 1) }
      l
  end
  
  private
  
  # list of question_type, label and classes
  def self.datas 
    @@datas ||= [ {:question_type => "poll", :label => "Poll", :class_name => QuestionPoll },
                  {:question_type => "feature", :label => "Feature", :class_name => QuestionFeature },
                  {:question_type => "filter", :label => "Filter", :class_name => QuestionFilter },
                  {:question_type => "tradeoff", :label => "Trade-Off", :class_name => QuestionTradeOff },
                  {:question_type => "tip", :label => "Tip", :class_name => QuestionTip },
                  {:question_type => "feature_value", :label => "Single-Topic", :class_name => QuestionFeatureValue },
                  {:question_type => "generic", :label => "Generic", :class_name => QuestionGeneric } ]
  end


      
end

class QuestionPoll < Question

  # create 2 choices, no recommendation...
  def create_template(definition)
    self.is_multiple = false
    self.label = "Your poll question..."    
    choice_1 = Choice::ChoiceSimple.create(:label => "choice 1", :author => author, :question => self, :product_filters => [])
    self.choices << choice_1
   	choice_2 = Choice::ChoiceSimple.create(:label => "choice 2", :author => author, :question => self, :product_filters => [])
    self.choices << choice_2    
  end
  
  
end

class QuestionFeature < Question

  belongs_to :feature
  
  # create 1 choice per value of the feature's domain 
  def create_template(definition)
    self.is_multiple = true
    f = Feature.find(definition[:feature_id])
    self.feature_id = f.id
    self.label = "Please select your favorite #{f.path}?"        
    product_filters = ProductFilter::ProductFilterFeature.create_split_from_feature(f, +1)
    product_filters.each { |product_filter|        
      choice = Choice::ChoiceOnFeature.create(:label => product_filter.as_string, :extract => "ok for all products where #{product_filter.as_extract}", 
        :author => author, :question => self, :product_filters => [product_filter], :feature => f)
      self.choices << choice
    }
    
    # copy the image of the feature value, for this question
    #PikiziLib.copy_flex_image_path("feature_value", fv.id, "question", id)
    
  end
  
end

class QuestionFilter < Question

  belongs_to :feature
  
  # create 1 choice per value of the feature's domain 
  def create_template(definition)
    self.is_multiple = true
    self.is_compensatory = false
    f = Feature.find(definition[:feature_id])
    self.feature_id = f.id
    self.label = "Please filter by #{f.path}?"        
    product_filters = ProductFilter::ProductFilterFeature.create_split_from_feature(f, +1)
    product_filters.each { |product_filter|        
      choice = Choice::ChoiceOnFilter.create(:label => product_filter.as_string, :extract => "ok for all products where #{product_filter.as_extract}", 
        :author => author, :question => self, :product_filters => [product_filter], :feature => f)
      self.choices << choice
    }
    
    # copy the image of the feature value, for this question
    #PikiziLib.copy_flex_image_path("feature_value", fv.id, "question", id)
    
  end
  
end


class QuestionTradeOff < Question
  
  belongs_to :feature_value_1, :class_name => "FeatureValue"
  belongs_to :feature_value_2, :class_name => "FeatureValue"
  
  # create 2 choices, each matching a product/feature
  def create_template(definition) 
    self.is_multiple = false
    p1 = Product.find(definition[:product_1_id])
    f1 = Feature.find(definition[:feature_1_id])
    fv1 = FeatureValue.find(:first, :conditions => ["product_id=? AND feature_id=?", p1.id, f1.id])
    self.feature_value_1 = fv1
    
    p2 = Product.find(definition[:product_2_id])
    f2 = Feature.find(definition[:feature_2_id])
    fv2 = FeatureValue.find(:first, :conditions => ["product_id=? AND feature_id=?", p2.id, f2.id])
    self.feature_value_2 = fv2
    
    self.label = "#{p1.label}<b> vs </b>#{p2.label}"
    self.extract = "Tradeoff between #{p1.label} #{f1.path} = #{fv1.value_as_string} <b> and </b>#{p2.label}  #{f2.path} = #{fv2.value_as_string}"
    product_filters_1 = [
    	ProductFilter::ProductFilterSimple.create_from_product(p1, +1),
    	ProductFilter::ProductFilterSimple.create_from_product(p2, -1)
    ]
    choice_1 = Choice::ChoiceOnProduct.create(:label => "#{p1.label} / #{fv1.value_as_string}", 
      :extract => "#{p1.label} on #{f1.path} = #{fv1.value_as_string}",
      :author => author, :question => self, :product_filters => product_filters_1, :product => p1)
    self.choices << choice_1
    PikiziLib.copy_flex_image_path("feature_value", fv1.id, "choice", choice_1.id)
    
    product_filters_2 = [
    	ProductFilter::ProductFilterSimple.create_from_product(p1, -1),
    	ProductFilter::ProductFilterSimple.create_from_product(p2, +1)
    ]
    choice_2 = Choice::ChoiceOnProduct.create(:label => "#{p2.label} / #{fv2.value_as_string}", 
      :extract => "#{p2.label} on #{f2.path} = #{fv2.value_as_string}",
      :author => author, :question => self, :product_filters => product_filters_2, :product => p2)
    self.choices << choice_2
    PikiziLib.copy_flex_image_path("feature_value", fv2.id, "choice", choice_1.id)
    
  end
  
end

# extrafield
# - tip_good_or_bad (1 == good, -1 == bad)
# - tip_tag_id (the tag_id matching this tip)
class QuestionTip < Question

  belongs_to :dtag, :class_name => "Dtag", :foreign_key => "tip_tag_id" # the mapping tag in tip_good_for or tip_bad_for feature
  belongs_to :feature_value
  belongs_to :tip_product_filter_yes, :class_name => "ProductFilter", :foreign_key => "tip_product_filter_yes_id"
  # create 2 choices (yes/no), matching feature  tips/good_for or tips/bad_for
  # model the tip
  def create_template(definition)
    self.is_multiple = false
    self.label = "Enter your tip"
    p = Product.find(definition[:product_id]) # the recommended product
    feature_path = definition[:feature_path] # definition[:feature_path] is either tips/good_for or tips/bad_for   
    search_in_categories_ids = p.category.self_and_ancestors.collect(&:id)
    f = Feature.get_node_from_path(feature_path, :conditions => "category_id IN (#{search_in_categories_ids.join(',')})") 
    fv = p.get_feature_value(f.id)
    raise "no featur evalue" unless fv
    self.feature_value = fv
     
    # create the FeatureValue for this product
    #tag_id = f.domain.check_value([label]).first # retrieve the tag in the domain (or create it)
    #f.domain(true)  # reload the domain (needed if a tag has been added)
    #fv = p.get_feature_value(f.id)
    #exiting_values = fv ? fv.value_genuine : []    
    #raise "error oups exiting_values=#{exiting_values.inspect} tag_id=#{tag_id.inspect}" unless exiting_values.is_a?(Array)
    #exiting_values << tag_id
    #p.set_value(f, exiting_values, "created by tip question") 
    # create the choices
    recommendation = case feature_path
    					when "tips/good_for" then +1
    					when "tips/bad_for" then -1
    					else
    						raise "parameter #{feature_path} is not valid"
    				end

    product_filter_yes = ProductFilter::ProductFilterFeature.create_from_feature(f, recommendation)	
    update_attribute(:tip_product_filter_yes, product_filter_yes)
    
    choice_yes = Choice::ChoiceOnTip.create(:label => "yes", 
      :extract => "explanation about this choice...",
      :author => author, :question => self, :product_filters => [product_filter_yes], :feature => f)
    self.choices << choice_yes

    choice_no = Choice::ChoiceOnTip.create(:label => "no", 
      :extract => "explanation about this choice...",
      :author => author, :question => self, :product_filters => [], :feature => f) # no filter
    self.choices << choice_no

  end
  
  def change_state_callback(event)
    product = feature_value.product
    feature = feature_value.feature
    case event
      when "test!"
        update_attribute(:tip_tag_id, feature.domain.check_value([label]).first) # retrieve the tag in the domain (or create it)
        tip_product_filter_yes.update_definition(:tag_ids => [tip_tag_id])
        values = product.get_feature_value_genuine(feature.id)
        values ||= []
        unless values.include?(tip_tag_id)
          values << tip_tag_id
          product.set_value(feature.id, values) 
        end
        # copy the image of the existing tag, of the subdomain if any, for this choice
        PikiziLib.copy_flex_image_path("tag", tip_tag_id, "question", id)
      when "test_is_ok!" 
        # don't do anything
      when "test_is_ko!", "reset!", "trash!"
        # remove the feature value for this product
        update_attribute(:tip_tag_id, nil)
        values = product.get_feature_value_genuine(feature.id)
        values.delete(tip_tag_id)
        product.set_value(feature.id, values) 
      else
        raise "unknown event"
    end
  end
  
end  

class QuestionFeatureValue < Question

  # create 2 choices (yes/no), matching one product/feature  
  belongs_to :feature_value
  
  def create_template(definition)
    self.is_multiple = false
    p = Product.find(definition[:product_id])
    f = Feature.find(definition[:feature_id])
    fv = FeatureValue.find(:first, :conditions => ["product_id=? AND feature_id=?", p.id, f.id])
    self.label = "Could you live with #{p.label} / #{fv.value_as_string} ?"    
    self.extract = "Describe your question..."
    self.feature_value = fv
    product_filter_yes = ProductFilter::ProductFilterSimple.create_from_product(p, +1)	
    choice_yes = Choice::ChoiceOnFeatureValue.create(:label => "yes", 
      :extract => "more text on this choice...",
      :author => author, :question => self, :product_filters => [product_filter_yes], :feature_value => fv)
    self.choices << choice_yes
    
    product_filter_no = ProductFilter::ProductFilterSimple.create_from_product(p, -1)
   	choice_no = Choice::ChoiceOnFeatureValue.create(:label => "no", 
      :extract => "more text on this choice...",
      :author => author, :question => self, :product_filters => [product_filter_no], :feature_value => fv)
    self.choices << choice_no
    # copy the image of the feature value, for this question
    PikiziLib.copy_flex_image_path("feature_value", fv.id, "question", id)
    
  end
  
end


class QuestionGeneric < Question
  
  def create_template(definition) end


  
end
