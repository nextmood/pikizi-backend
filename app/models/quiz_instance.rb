# A QuizInstance is the execution of a Quizz by a customer
# i.e a list of questions/answers
class QuizInstance < ActiveRecord::Base
  
  belongs_to :quiz
  
    
end

