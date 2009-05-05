class FeatureValuesController < ApplicationController
  
  caches_page :thumbnail
  
  in_place_edit_for :feature_value, :value_genuine
  
  # GET /feature_values/1
  # GET /feature_values/1.xml
  def show
    @feature_value = FeatureValue.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @feature_value }
    end
  end
  
  # GET /feature_values/1/thumbnail.jpg
  def thumbnail
    @feature_value = FeatureValue.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # POST /feature_values/1/rate
  # see plugin ajaxful rating
  def rate
    @feature_value = FeatureValue.find(params[:id])
    @feature_value.rate(params[:stars], current_user, params[:dimension])
    # ajaxful-rating-user-featurevalue-255
    id = "ajaxful-rating-#{!params[:dimension].blank? ? "#{params[:dimension]}-" : ''}featurevalue-#{@feature_value.id}" 
    render :update do |page|
      page.replace(id, ratings_for(@feature_value, current_user, :dimension => params[:dimension], :small_stars => true, 
				:remote_options => {:method => :post, :url => rate_feature_value_path(@feature_value.id)}))
      page.visual_effect :highlight, id
    end
  end
  
  
  # this is a rjs form
  def update_current_value
    feature_value = FeatureValue.find(params[:feature_value_id])
    new_value = params["feature_value_#{feature_value.id}"]
    puts "new_value =#{new_value.inspect} "
    feature_value.set_value(new_value, nil, nil, current_user)
    render :update do |page|  end
  end
  
  # this is a rjs
  def update_tag_value
    feature_value = FeatureValue.find(params[:feature_value_id])
    feature_value.set_value(params[:tag_id], nil, nil, current_user)
    render :update do |page|  end
  end
  
  # this is a rjs
  def update_tags_value
    feature_value = FeatureValue.find(params[:feature_value_id])
    tag_id = params[:tag_id].to_i
    current_value  = feature_value.value_genuine || []
    if current_value.include?(tag_id)
      current_value.delete(tag_id)
    else
      current_value << tag_id
    end
    feature_value.set_value(current_value, nil, nil, current_user)
    render :update do |page|  end
  end
  
  
end
