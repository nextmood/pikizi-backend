require 'net/http'

class QuizzesController < ApplicationController
  
  in_place_edit_for :quiz, :label
  in_place_edit_for :quiz, :extract
  in_place_edit_for :quiz, :media_url
  
  def quiz_1
    product_id = params[:product_id]
    if product_id
      @product = Product.find(product_id) 
    else
      flash[:notice] = "Select a product, first !"
      redirect_to("/search")
    end
  end
  
  def quiz_2
    if (@wishlist = Wishlist.get_current(current_user, session)).products.size < 2
      flash[:notice] = "Search products and add them to your wish list, first"
      redirect_to("/search")
    end
  end
    
  # GET /quizzes
  # GET /quizzes.xml
  def index
    @quizzes = Quiz.find(:all)
    @quizzes = @quizzes.group_by(&:category)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @quizzes }
    end
  end

  # GET /quizzes/1
  # GET /quizzes/1.xml
  def show
    @quiz = Quiz.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quiz }
    end
  end

  # POST /quizzes/add_new_default_quizz
  def add_new_default_quizz
    @quiz = Quiz.create(:author => current_user, :label => "new quizz", :category_id => params[:category_id])
    redirect_to(quizzes_path)
  end

  
  # GET /quizzes/1/edit
  def edit
    @quiz = Quiz.find(params[:id])
  end

  # GET /quizzes/1/export2engine    
  def export2engine
    @quiz = Quiz.find(params[:id])
    @quiz.before_export2engine
    # request engine to import all datas from this quiz
    begin
      Net::HTTP.get_response(URI.parse("#{ENGINE_URL}/quizzes/#{@quiz.id}/load_from_backend.xml"))
      @export2engine_results = "Quiz loaded in Engine 
        <a href='#{ENGINE_URL}/new_quiz/K32445/#{@quiz.id}'>start quiz on engine</a>
        <a href='/quizzes/#{@quiz.id}/stats_from_engine'>show statistics</a>"
    rescue
      flash[:error] = "I can't connect to the recommendation engine @ #{ENGINE_URL}"
      @export2engine_results = nil
    end
  end

  # GET /quizzes/1/get_stats_from 
  def stats_from_engine
    @quiz = Quiz.find(params[:id])
    @stats = @quiz.stats_from_engine
  end
  
  # PUT /quizzes/1
  # PUT /quizzes/1.xml
  def update
    @quiz = Quiz.find(params[:id])

    respond_to do |format|
      if @quiz.update_attributes(params[:quiz])
        flash[:notice] = 'Quiz was successfully updated.'
        format.html { redirect_to(@quiz) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quiz.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quizzes/1
  # DELETE /quizzes/1.xml
  def destroy
    @quiz = Quiz.find(params[:id])
    @quiz.destroy

    respond_to do |format|
      format.html { redirect_to(quizzes_url) }
      format.xml  { head :ok }
    end
  end
end
