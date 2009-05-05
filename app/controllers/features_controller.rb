class FeaturesController < ApplicationController
  
  caches_page :thumbnail
  
  # GET /features/1
  # GET /features/1.xml
  def show
    @feature = Feature.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @feature }
    end
  end
  
  # GET /features/1/thumbnail.jpg
  def thumbnail
    @feature = Feature.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # edit the header (name and description) of a feature
  def update_feature_header
    feature = Feature.find(params[:feature_id])
    is_a_new_label = (params[:label] != feature.label)
    feature.update_attributes({:label => params[:label], :automatic_rating_mode => params[:automatic_rating_mode], :extract => params[:extract]})
    if is_a_new_label
      Feature.rebuild!
      feature.update_path_and_sort
    end      
    redirect_to(features_category_path(feature.category_id)) 
  end
  
  
  
  # a user destroy a product's feature
  def destroy_feature
    feature = Feature.find(params[:feature_id], :include => :category)
    feature.remove_node
    redirect_to(features_category_path(feature.category_id)) 
  end
  

  
end
