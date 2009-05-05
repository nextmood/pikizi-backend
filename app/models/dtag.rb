# test
class Dtag < ActiveRecord::Base
    
  # see http://github.com/Squeegy/fleximage/tree/master
  acts_as_fleximage do
    image_directory 'uploaded_photos/tag'
    require_image false
    default_image_path "public/images/default/default_tag.png" 
  end
      
end
