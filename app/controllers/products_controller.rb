# - classic CRUD methods (generated)
# - Managing features via a product (this a proxy to the methods of the category's model)
class ProductsController < ApplicationController
    
  caches_page :thumbnail
  
  in_place_edit_for :product, :label
  in_place_edit_for :product, :url
  in_place_edit_for :product, :description
  
  #before_filter :login_required, :except => [:index, :show]
  
  # GET /products
  # GET /products.xml
  def index
    @products = Product.find(:all, :include => [:author])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @products }
    end
  end
  

    	 
  # GET /products/1
  # GET /products/1.xml
  def show
    @product = Product.find(params[:id].to_i)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @product }
    end
  end

  # GET /products/1/thumbnail.jpg
  def thumbnail
    @product = Product.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end

  # GET /products/1/thumbnail_150.jpg
  def thumbnail_150
    @product = Product.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end

  # GET /products/1/thumbnail_150.jpg
  def thumbnail_120
    @product = Product.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # get /create_product_from_amazon/:category_id/:asin
  def new_from_amazon
    # create the product
    category = Category.find(params[:category_id]) 
    raise "no category_id for product creation from amazon" unless category
    @product, @error = ApiAmazon.create_new_product_from_amazon(params[:asin], current_user, category.id)
    if !@error and @product.valid?
      raise "No product id created #{@product.inspect}" if @product.id.nil?
      # create the reviews
      nb_reviews = ApiAmazon.create_new_reviews_from_amazon(@product)
      flash[:notice] = "Product (and #{nb_reviews} reviews were successfully created from Amazon."
      redirect_to("/products/#{@product.id}/edit")
    else
      if @error
        flash[:error] = "Unable to import this product from amazon<br/>error msg=#{@error}"
      end
      @product.errors.each_full { |msg|  flash[:error] << "#{msg}<br/>"} if @product
      redirect_to "/search_amazon/#{category.id}/#{params[:asin]}"
    end
  end
  

  
  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
  end

  # POST /products
  # POST /products.xml
  def create
    @product = Product.new(params[:product])
    if @product.save
      flash[:notice] = 'Product was successfully created.'
      redirect_to(@product)
    else
      render :action => "new"
    end
  end

  # PUT /products/1
  # PUT /products/1.xml
  def update    
    if new_category_label = params[:new_category_label] and new_category_label != ""
      parent_category_id = params[:product][:category_id]
      category_id = Category.create(:label => new_category_label, :parent_id => parent_category_id).id
      params[:product][:category_id] = parent_category_id
    end
    @product = Product.find(params[:id])    
    @product.compute_similarities(-1) if category_has_changed = (params[:product] and params[:product][:category_id] and params[:product][:category_id] != @product.category_id.to_s)

    respond_to do |format|
      if @product.update_attributes(params[:product])
        flash[:notice] = "Product was successfully updated."
        @product.compute_similarities(+1) if category_has_changed
        format.html { render :action => "edit" }
        format.xml  { head :ok }
      else
        @product.compute_similarities(+1) if category_has_changed
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
    
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to(:controller => "/") 
  end
  
end
