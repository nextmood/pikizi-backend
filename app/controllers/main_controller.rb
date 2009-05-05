
class MainController < ApplicationController
  
  # Home page
  def index
    search_box_set({:title_search_box_genuine => "Search product",
                    :title_search_box_results => "Search results",
                    :title_1_search_result => "",
                    :title_2_search_form_genuine => "Search our catalog",
                    :title_2_search_categories => "or browse categories",
                    :title_2_search_form_results => "Search again",
                    :postfix_html_genuine => ""})
  end
  

  # admin page
  def admin
  end
    
  # -------------------------------------------
  # Managing flex image
  # --------------------------------------------
  
  # following line to import object definitions ... weird! (to import subclasses)
  Feature; Choice; Question
  
  
  # open/close the media editor for a fleximage (get)
  # url /fleximage_editor/:ar_object_class/:ar_object_id/:display_thumbnail/:display_editor
  def fleximage_editor
    
    ar_object = Kernel::const_get(params[:ar_object_class]).find(params[:ar_object_id])
    display_editor = (params[:display_editor] == "false")
    display_thumbnail = (params[:display_thumbnail] == "true")
    
    render :update do |page|  
      page.replace(MainController.fleximage_domid(ar_object),
              render(:partial => "/main/media_edit", 
                    :locals => {:ar_object => ar_object, 
                                :timestamp => nil,
                                :display_thumbnail => display_thumbnail, 
                                :display_editor => display_editor})
              )
		end
  end
  
    
  # this a post, uploading :image_file_url and :media_url
  # for a flex image
  # /fleximage_upload/:ar_object_class/:ar_object_id/:display_thumbnail
  def self.fleximage_domid(ar_object) "fleximage_#{ar_object.class}_#{ar_object.id}" end
    
  def fleximage_upload 
    
    ar_object = Kernel.const_get(params[:ar_object_class]).find(params[:ar_object_id])
    display_thumbnail = (params[:display_thumbnail] == "true")
    display_thumbnail_opposite = (display_thumbnail == false)
    
    if ar_object.update_attributes(params[:media])
      @messages = 'Media updated'
      expire_page "/#{ar_object.class.table_name}/#{ar_object.id}/thumbnail.jpg"      
    else
      @messages = 'Oups update media'
      ar_object.errors.each { |field, msg| puts "*********  field:#{field} --> #{msg}" }
    end
    
    render :update do |page|  
      page.replace(MainController.fleximage_domid(ar_object),
              render(:partial => "/main/media_edit", 
                    :locals => {:ar_object => ar_object, 
                                :timestamp => "?time=#{Time.now.to_i}",
                                :display_thumbnail => display_thumbnail,
                                :display_editor =>  display_thumbnail_opposite})
              )
		end
  end
  
	


  def self.image_domid(ar_object) "image_#{ar_object.class}_#{ar_object.id}" end
  # this a post, uploading :image_file_url
  # for a flex image
  # /upload_url_image/:ar_object_class/:ar_object_id
  def image_url_upload
    ar_object = Kernel.const_get(params[:ar_object_class]).find(params[:ar_object_id])
    ar_object.image_file_url = params[:image_file_url]
    if ar_object.save
      @messages = 'fleximage updated'
    else
      @messages = 'Oups updating fleximage'
      ar_object.errors.each { |field, msg| puts "*********  field:#{field} --> #{msg}" }
    end
    render :update do |page|  
      page.replace(MainController.image_domid(ar_object),
        render(:partial => "/main/image_editor", :locals => {:title => params[:title], :ar_object => ar_object }))
		end
  end
    
  def self.media_domid(ar_object) "media_#{ar_object.class}_#{ar_object.id}" end
  # this a post, uploading :media_file_url
  # /upload_url_media/:ar_object_class/:ar_object_id
  def media_url_upload
    ar_object = Kernel.const_get(params[:ar_object_class]).find(params[:ar_object_id])
    ar_object.media_url = params[:media_url]
    if ar_object.save
      @messages = 'media updated'
    else
      @messages = 'Oups updating fleximage'
      ar_object.errors.each { |field, msg| puts "*********  field:#{field} --> #{msg}" }
    end
    render :update do |page|  
      page.replace(MainController.media_domid(ar_object),
        render(:partial => "/main/media_editor", :locals => {:title => params[:title], :ar_object => ar_object }))
		end
  end
  
end
