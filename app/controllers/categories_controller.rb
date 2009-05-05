class CategoriesController < ApplicationController


  
  caches_page :thumbnail
 
  # GET /categories
  # GET /categories.xml
  def index
    @roots_categories = Category.roots
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roots_categories }
    end
  end


  # GET /categories/1/matrix_products
  # POST /categories/1/matrix_products  
  def matrix_products
    @category = Category.find(params[:id])
    @products_all = @category.products_genuine      
    product_ids_filter =  if params[:product_ids_filter]
                            params[:product_ids_filter].collect { |p_id| Integer(p_id) }
                          else
                            @products_all.collect(&:id)
                          end
    # limit the number to 4
    product_ids_filter = product_ids_filter.first(4) if product_ids_filter.size > 4
    @products = @products_all.select { |p| (product_ids_filter.size == 0) || product_ids_filter.include?(p.id) }
  end

  # GET /categories/1.format
  # GET /categories/1.xml
  def show
    @category = Category.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/1/thumbnail.jpg
  def thumbnail
    @category = Category.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end


  # GET /categories/new
  # GET /categories/new.xml
  def new
    @category = Category.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /categories
  # POST /categories.xml
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        flash[:notice] = 'Category was successfully created.'
        format.html { redirect_to(@category) }
        format.xml  { render :xml => @category, :status => :created, :location => @category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to(@category) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end


  # GET /categories/2/add_new_product
  def add_new_product
    product = Category.find(params[:id]).add_new_default_product("new product", current_user) 
    redirect_to("/products/#{product.id}/edit")
  end
  
  # add a feature to the model for this category
  # POST /categories/1/add_new_default_feature
  def add_new_default_feature
    category = Category.find(params[:id])
    error_when_creating_feature = false
    begin
      new_feature = category.add_new_default_feature(params[:feature_type], params[:feature_parent_id], params[:label_new_feature], nil, current_user)
    rescue Exception => e
      error_when_creating_feature = e.to_s
    end
    respond_to do |format|
        if error_when_creating_feature
          flash[:error] = "Feature #{params[:label_new_feature]} was not created in category #{category.label}<br/>
          error=#{error_when_creating_feature}<br/>
          To create a new feature under an existing one, use name_existing_feature/name_new_feature as label"
        else
          flash[:notice] = "Feature #{new_feature.label} was successfully created in category #{category.label}"
        end
        format.html { redirect_to(features_category_path(category)) }
        format.xml  { render :xml => new_feature, :status => :created }
    end
  end
  
  
  # POST /categories/1/add_new_default_question
  def add_new_default_question
    @category = Category.find(params[:id])
    question_type = params[:question_type]
    new_question = case question_type
      when "poll" then @category.add_new_default_question(question_type, nil, current_user)
      when "feature" then @category.add_new_default_question(question_type, nil, current_user, 
        :feature_id => params[:feature_id])  
      when "filter" then @category.add_new_default_question(question_type, nil, current_user, 
        :feature_id => params[:feature_id])
      when "tradeoff" then @category.add_new_default_question(question_type, nil, current_user, 
        :product_1_id => params[:product_1_id], :feature_1_id => params[:feature_1_id],
        :product_2_id => params[:product_2_id], :feature_2_id => params[:feature_2_id])
      when "tip" then @category.add_new_default_question(question_type, nil, current_user, 
        :product_id => params[:product_id], :feature_path => params[:feature_path])
      when "feature_value" then @category.add_new_default_question(question_type, nil, current_user,
        :product_id => params[:product_id], :feature_id => params[:feature_id])
      when "generic" then @category.add_new_default_question(question_type, nil, current_user)
      else
        nil
      end
      if new_question
        redirect_to(edit_question_path(new_question)) 
      elsif question_type[0..3] == "pre_"
          # ask for parameters before to create the question
          render(:action => "bc_question_#{question_type[4..1000]}")
      else
        flash[:notice] = "Oups creating question"
        redirect_to(category_questions_path(@category)) 
      end
  end
  

  
  # edit categories tree
  def add_sub_category
    parent_category = Category.find(params[:parent_category_id]) 
    Category.add_new_default_category("a new category", parent_category, current_user)
    redirect_to("/dashboard/categories_edition")
  end
  
  # edit categories tree  
  #TODO same as below ! unify
  def remove_category
    Category.find(params[:category_id]).remove_node
    redirect_to("/dashboard/categories_edition")
  end
  
  
  # GET /categories/1/features
  # GET /categories/1/features.xml
  # return a list of features objects for a given category  
  def features
    @category = Category.find(params[:id])
    @categories = @category.self_and_ancestors
    @trees = @categories.collect {|cat| [cat, Feature.node_roots(:conditions => ["category_id=?", cat.id])] }
    respond_to do |format|
      format.html # features.html.erb
      format.xml  { render :xml => @trees }
    end
  end
  
  
  private
  

  
end
