# The reviews parser takes a set of Review objects and
# produce Feature, FeatureValue and FeatureReview objects
class ReviewsParser
  
  # +input+ is a list of reviews object (if nil, retrieve all reviews in state "to_process") 
  # +input+ could also be a batch_id (string) provided when created the reviews
  def initialize(input)
    @reviews =  if input.is_a(String)
                  Review.find(:all, ["batch_id='?'", reviews])
                elsif input.nil?
                  Review.find(:all, ["state='?'", "to_process"])
                else
                  input
                end
  end
  
  # process and generates Feature, FeatureValue and FeatureReview objects
  def process()
  end
  
end