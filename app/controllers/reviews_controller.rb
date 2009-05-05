require 'pikizi_lib'

class ReviewsController < ApplicationController

  in_place_edit_for :review, :content
  in_place_edit_for :review, :rating
  
  # get /products/1/reviews -> list all reviews for this product
  # get /reviews -> list all reviews, whatever the product
  # get /reviews.xml -> list (in xml) all reviews, whatever the product
  def index
    if params[:product_id].blank?

      @reviews_per_category_product = Category.build_reviews_tree
      
      respond_to do |format|
          format.html { render :action => "list_all" }
          format.xml  { render(:partial => "/reviews/list_all.xml.erb", :locals => {:reviews_per_category_product => @reviews_per_category_product, :start => true }) }
          
      end
    else
      @product = Product.find(params[:product_id]) 
      current_user
      @authored_review = Review.find(:first, :conditions => ["product_id = ? AND author_id = ?", @product.id, @current_user.id])
      @reviews = Review.find(:all, :conditions => ["product_id = ?", @product.id], :order => "created_at DESC")
    end
  end
  
  # get /reviews/1
  def show
    @review = Review.find(params[:id], :include => [:author, :product])
  end
  
  # get /set_rating_feature_review/:feature_review_id/rating
  # this is a rjs
  def set_rating_feature_review
    rating = case params[:rating]
                when "ok" then 1.0
                when "ko" then -1.0
                else
                  0.0
                end
    feature_review = FeatureReview.find(params[:feature_review_id])
    feature_review.update_attribute(:rating, rating)
    render :update do |page|  
		  page.replace("set_rating_feature_review_#{feature_review.id}",
              render(:partial => "/reviews/feature_rating", :locals => {:feature_review => feature_review}))
    end
  end
  
  # get /reviews/compute_rating/1
  # recompute the average rating of the product (and all its features)
  # which is reviewed
  # this is a development tool, should be a cron call
  def compute_rating
    review_id = params[:id]
    review = Review.find(review_id, :include => :product)
    Product.compute_rating(review.product)
    redirect_to edit_review_path(review_id)
  end
  
  # POST /products/1/reviews
  def create
    product = Product.find(params[:product_id])
    @review = product.create_review(current_user, {:summary => "my review"})
    redirect_to(edit_review_path(@review))
  end
  
  # get /reviews/1/edit
  def edit
    @review = Review.find(params[:id], :include => [:author, :product])
  end

  # list of reviews
  # /reviews
  # /reviews/filter/:id
  # return a 3 tree
  # [category [products [reviews]]]
  def list
    case params[:filter]
      when "category" 
        [Category.find(params[:id]).build_reviews_tree]
      when "product" 
        product = Product.find(params[:id])
        tree = [[product.category, [product, product.reviews]]] 
      else
        category = :all
        product = :all
    end
  end
 

  
  # rjs
  def create_or_update_review
    review_id = params[:review_id]
    product_id = params[:product_id]
    rating = PikiziLib.clean_string(params[:rating])
    url = PikiziLib.clean_string(params[:url])
    summary = PikiziLib.clean_string(params[:summary])
    content = PikiziLib.clean_string(params[:content])
    author_weight = current_user.weight
    author_id = current_user.id
    
    errors = []
    errors << "field rating is missing" unless rating
    errors << "field summary is missing"  unless summary
    errors << "the url or a text of the review is missing"  unless content or url
    
    previous_review = nil
    review =  if review_id and review_id != ""
                previous_review = Review.find(review_id)
                previous_review.clone
              else
                Review.new(:product_id => product_id, :author_id => author_id, :author_weight => author_weight)
              end
              
    if errors.size > 0
      flash[:error] = "Your review has not been updated<ul>"
      flash[:error] << errors.collect { |message_error|  "<li>#{message_error}</li>"}.join << "</ul>"
    else
      review.rating = rating
      review.url = url || "/localhost:3000/show_review/#{review.id}"
      review.summary = summary
      review.content = content
      review.author_weight = author_weight 
      if review.save
        previous_review.update_counters(-1) if previous_review
        review.update_counters()
        flash[:notice] = "Your review has been updated"
      else
        flash[:notice] = "something went wrong !"
      end
    end
    render :update do |page|
      page.replace_html("create_or_update_review", render(:partial => "/reviews/form", :locals => { :review => review, :hidden => false }))                        
    end
  end
  

  # rjs
  def destroy
    @review = Review.find(params[:id])
    @review.destroy
    redirect_to(:controller => "reviews", :action => "index") 
  end
  
  
  
end