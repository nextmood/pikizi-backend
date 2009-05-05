class DtagsController < ApplicationController
  
  caches_page :thumbnail
  
  in_place_edit_for :tag, :label

  # GET /tags
  # GET /tags.xml
  def index
    @tags = Dtag.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tags }
    end
  end
  
  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = Dtag.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag }
    end
  end
  
  # GET /tags/1/thumbnail.jpg
  def thumbnail
    @tag = Dtag.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # GET /tags/new
  # GET /tags/new.xml
  def new
    @tag = Dtag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Dtag.find(params[:id])
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Dtag.new(params[:tag])

    respond_to do |format|
      if @tag.save
        flash[:notice] = 'Dtag was successfully created.'
        format.html { redirect_to(@tag) }
        format.xml  { render :xml => @tag, :status => :created, :location => @tag }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = Dtag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Dtag was successfully updated.'
        format.html { redirect_to(@tag) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = Dtag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(tags_url) }
      format.xml  { head :ok }
    end
  end
  
end
