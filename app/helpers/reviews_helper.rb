module ReviewsHelper
  
  # convert a rating (-1.0 -0- 1.0) to 
  # a hot/trah rating
  def as_trash_or_hot(rating)
    if rating.nil?
      image_tag('icons/feature_blank.png', :border => 0)
    elsif rating > 0.5
			image_tag('icons/feature_hot.png', :border => 0)
		elsif rating >= -0.5 and rating <= 0.5
			image_tag('icons/feature_neutral.png', :border => 0)
		elsif rating and rating <= -0.5
			image_tag('icons/feature_trash.png', :border => 0)
		end
  end
  
end
