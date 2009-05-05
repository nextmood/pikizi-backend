require 'tip'

class ChoicesController < ApplicationController
  
  caches_page :thumbnail
  
  in_place_edit_for :choice, :label
  in_place_edit_for :choice, :extract
  in_place_edit_for :choice, :url
    
  # GET /choices/1/thumbnail.jpg
  def thumbnail
    @choice = Choice.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # GET /choices/1/thumbnail.jpg
  def thumbnail_150
    @choice = Choice.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # POST /choices/1/set_feature
  # Set the feature associated to this choice
  def set_feature
    choice = Choice.find(params[:id])
    feature = Feature.find(params[:feature_id])
    question.create_choices_for_feature(current_user, feature)
    choice.update_attribute(:feature, feature)
    redirect_to edit_question_path(question)
  end
  
  # action triggered by the drag and drop
  # add a TipSimple to a choice
  # GET /choices/tip_add/choice_id/dom_id
  # this is a rjs
  def tip_add
    choice = Choice.find(params[:choice_id])
    product =  Product.find(params[:dom_id].split('_').last)
    new_tip = choice.tips.create(:product => product, :choice => choice, :quality => 1.0, :confidence => 1.0)
    render :update do |page|
      page.insert_html(:top, "dropzone_choice_#{choice.id}", :partial => "/main/thumbnail", 
          :locals => {:ar_object => product, :container_tag => "li", :prefix => "reco_choice_#{choice.id}", :corner_link => "/choices/tip_remove/#{new_tip.id}" })
    end
  end

  # GET /choices/tip_remove/tip_id
  # remove a tip from a choice
  # this is a rjs
  def tip_remove
    tip_id = params[:id]
    tip = Tip.find(tip_id)
    choice_id = tip.choice_id
    product_id = tip.product_id
    tip.destroy
    render :update do |page|
      page.remove("reco_choice_#{choice_id}_#{product_id}")
    end
  end

  # parameters
  # id -> choice
  # recommendation (+1 or -1)
  # type_filter (product or feature or rating)
  # feature_id if type_filter==feature
  # feature_id if type_filter==rating
  # product_id if type_filter==product
  # GET /choices/:id/add_filter
  def add_filter
    choice = Choice.find(params[:id])
    recommendation = Integer(params[:recommendation])
    product_filter_feature =  case params[:type_filter]
        when "product" then ProductFilter::ProductFilterSimple.create_from_product(Product.find(params[:product_id]), recommendation)
        when "feature" then ProductFilter::ProductFilterFeature.create_from_feature(Feature.find(params[:feature_id]), recommendation)
        when "rating" then ProductFilter::ProductFilterRating.create_from_rating(Feature.find(params[:feature_id]), recommendation)
      end
    choice.product_filters << product_filter_feature
    redirect_to(edit_question_path(choice.question_id))
  end
  
  # GET /choices/remove_filter/:product_filter_id
  def remove_filter
    product_filter = ProductFilter.find(params[:id])
    choice = product_filter.choice
    choice.product_filters.delete(product_filter)
    redirect_to(edit_question_path(choice.question_id))
  end
  
  # action triggered by the drag and drop
  # set the associated product for a ChoiceTradeoff
  # GET /questions/tradeoff_product_add/choice_id/dom_id
  # this is a rjs
  def tradeoff_product_add
    choice = Choice.find(params[:choice_id])
    product =  Product.find(params[:dom_id].split('_').last)
    choice.tips.clear
    choice.tips.create(:product => product, :choice => choice, :quality => 1.0, :confidence => 1.0)
    render :update do |page|
      page.replace_html("dropzone_choice_#{choice.id}", :partial => "/main/thumbnail", 
          :locals => {:ar_object => product, :container_tag => "li", :prefix => "reco", :corner_link => "/choices/tradeoff_product_remove/#{choice.id}" })
    end
  end
  
  # GET /questions/tradeoff_product_remove/choice_id
  # remove the product associated with the ChoiceTradeoff
  # this is a rjs
  def tradeoff_product_remove
    choice = Choice.find(params[:id]) 
    choice.tips.clear
    render :update do |page|
      page.replace_html("dropzone_choice_#{choice.id}", "")
    end
  end
  
  
  
end
