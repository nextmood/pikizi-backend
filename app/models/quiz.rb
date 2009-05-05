# A Quiz is made of a pre-defined list of Product objects and a dynamically computed sequence of Question on which a user answers:
# * one of the possible Choice available for the Question
# * or "unknown" for "i don't understand/care etc... the Question" 
# the result of a quiz is a list of Product ordered by user's affinities
class Quiz < ActiveRecord::Base
  

  belongs_to :category
  belongs_to :author, :class_name => "User"
  
  acts_as_state_machine :initial => :draft
  
  state :draft
  
  # image associated with this quiz
  acts_as_fleximage do
    image_directory 'uploaded_photos/quiz'
    require_image false
    default_image_path "public/images/default/default_quiz.png" 
  end
  
  # action to take before to export data to the engine
  def before_export2engine
    
  end
  
  # importing statistics from the engine
  def stats_from_engine
    
    # get the stats for the quizz
    row = ApplicationController.engine_connection.query("
      SELECT quizzes.id, 
            COUNT(quiz_instances.id),
            COUNT(DISTINCT quiz_instances.session_key),
            SUM(quiz_instances.nb_answers)
      FROM quizzes, quiz_instances
      WHERE quiz_instances.quiz_id = quizzes.id AND
            quizzes.quiz_key = '#{id}'
      GROUP BY quizzes.id").fetch_row
    quiz_engine_id = Integer(row[0])
    stats = {
      :nb_quiz_instances => Integer(row[1]),
      :nb_users => Integer(row[2]),
      :nb_answers => Integer(row[3])
    }
    
    # get the questions from the quiz engine
    hash_question_id_stats = {}
    res = ApplicationController.engine_connection.query("
      SELECT questions.question_key, 
             questions.id, 
             questions.discrimination,
             questions.interest,
             questions.popularity,
             questions.confidence,
             quiz_questions.nb_answers
      FROM quiz_questions, questions
      WHERE quiz_questions.quiz_id = #{quiz_engine_id} AND
            questions.id = quiz_questions.question_id
      ORDER BY questions.popularity DESC")
    ranking_index = 1
    while row = res.fetch_row do 
      hash_question_id_stats[q_key = Integer(row[0])] = {
        :question_key => q_key,
        :discrimination => Float(row[2]),
        :interest => Float(row[3]),
        :popularity => Float(row[4]),
        :confidence => Float(row[5]),
        :nb_answers => Integer(row[6]),
        :ranking => ranking_index }
      ranking_index += 1
      hash_question_id_stats[q_key][:choices] = Question.stats_from_engine(quiz_engine_id, Integer(row[1]))
    end
    stats[:question_stats] = hash_question_id_stats.collect { |p_key, stat| stat } 
    stats[:question_stats].sort! { |h1, h2|  h2[:popularity] <=> h1[:popularity] }
    
    # get the products from the quiz engine
    hash_product_id_stats = {}
    res = ApplicationController.engine_connection.query("
      SELECT products.product_key, 
             quiz_products.popularity,
             quiz_products.nb_selected,
             quiz_products.nb_rejected,
             quiz_products.nb_buy,
             quiz_products.nb_details
      FROM quiz_products, products
      WHERE quiz_products.quiz_id = #{quiz_engine_id} AND
            products.id = quiz_products.product_id
      ORDER BY quiz_products.popularity DESC")
    ranking_index = 1
    while row = res.fetch_row do 
      hash_product_id_stats[p_key = Integer(row[0])] = {
        :product_key => p_key,
        :popularity => Integer(row[1]),
        :nb_selected => Integer(row[2]),
        :nb_rejected => Integer(row[3]),
        :nb_buy => Integer(row[4]),
        :nb_details => Integer(row[5]),
        :ranking => ranking_index  }
      ranking_index += 1
    end
    stats[:product_stats] = hash_product_id_stats.collect { |p_key, stat| stat } 
    stats[:product_stats].sort! { |h1, h2|  h1[:ranking] <=> h2[:ranking] }   
    stats
  end
   
end

class QuizCustom < Quiz
  
  has_many :quiz_products, :dependent => :destroy
  has_many :products, :through => :quiz_products
  has_many :quiz_questions, :dependent => :destroy
  has_many :questions, :through => :quiz_questions 
   
end



class QuizCategory < Quiz
  
   def questions() category.questions_all end
   def products() category.products_all end
   
   # action to take before to export data to the engine
   def before_export2engine
     raise "error #{self.inspect} has no category " unless self.category
     update_attribute(:label, "#{self.category.label}'s default quizz")
     QuizProduct.delete_all(:quiz_id => id)
     products.each { |product| QuizProduct.create(:product_id => product.id, :quiz_id => id) }
     QuizQuestion.delete_all(:quiz_id => id)
     questions.each { |question| QuizQuestion.create(:question_id => question.id, :quiz_id => id) }
     # recompute all tips for this each question
     questions.each { |question| question.compute_tips  }
     
     # get the feature values 
     products.each { |product|
       carriers = product.get_feature_value_string(110)
       carriers = carriers ? carriers.join(",") : 'n/a'
       product.update_attributes(:data_carriers => carriers,
                                 :data_rating => rand(5),
                                 :data_price => product.get_feature_value_string(143)) 
     }
   end
     
end
