class QuestionsController < ApplicationController
  
  caches_page :thumbnail
  
  in_place_edit_for :question, :label
  in_place_edit_for :question, :extract
  in_place_edit_for :question, :url
  in_place_edit_for :question, :media_url
  in_place_edit_for :question, :tag_list
  
  
  def to_review
    
    # organize type per { question => { choice_id => [tip,...], ...}, question2 => ... }
    @questions = {}
    if current_user
      Tip.list_to_approve_by_user(current_user, nil).each { |tip| 
        @questions[tip.question] = {} unless @questions[tip.question]
        @questions[tip.question][tip.choice_id] = [] unless @questions[tip.question][tip.choice_id]
        @questions[tip.question][tip.choice_id] << tip
      }
    end
  end

  # get /categories/1/questions -> list all questions for this category
  # get /users/1/questions -> list all questions, authored by this user
  # get /quizzes/1/questions -> list all questions in this quiz
  # get /products/1/questions -> list (in xml) all reviews, whatever the product
  # get /questions.xml -> list (in xml) all questions in database
  
  def index    
    if !params[:product_id].blank?
      @product = Product.find(params[:product_id])
      @filter_questions = "Product #{@product.label}"
      @category = @product.category
      @questions = Question.find(:all, :include => {:choices => :tips}, :order => "created_at DESC", 
          :conditions => ["tips.product_id=?", @product.id])
    elsif !params[:quiz_id].blank?
      @quiz = Quiz.find(params[:quiz_id])
      @filter_questions = "Quiz #{@quiz.label}"
      @category = @quiz.category
      @questions = Question.find(:all, :include => [:quiz_questions, :choices ], :order => "created_at DESC",
          :conditions => ["quiz_questions.quiz_id=?", @quiz.id])
    elsif !params[:category_id].blank?
      @category = Category.find(params[:category_id])
      @filter_questions = "in category #{@category.path_without_root}"
      @questions = Question.find(:all, :include => :choices, :order => "created_at DESC",
          :conditions => ["questions.category_id=?", @category.id])
    else
      @filter_questions = "All questions"
      @questions = Question.find(:all)
      @category = current_user.expert_in_category
    end        
    respond_to do |format|
      format.html {  } # /questions index.erb.html
      format.xml  { render(:xml => @questions) } 
    end
  end
  

  
  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
    end
  end  
  
  # GET /questions/1/preview
  # this is a rjs
  def preview
    @question = Question.find(params[:id])
    render :update do |page|  
		  page.replace(question_dom_id(@question.id),
              render(:partial => "/questions/show", :locals => {:question => @question}))
    end
  end
  
  def edit
    @question = Question.find(params[:id])
  end
  
  # GET /questions/1/thumbnail.jpg
  def thumbnail
    @question = Question.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # GET /questions/1/thumbnail.jpg
  def ibackground
    @question = Question.find(params[:id])
    respond_to do |format|
      format.jpg
    end
  end
  
  # GET /remove_choice/:choice_id
  # remove a choice from a question
  def remove_choice
    choice = Choice.find(params[:choice_id])
    question_id = choice.question_id
    choice.destroy
    redirect_to edit_question_path(question_id)
  end
  
  # compute the products matching a question features / choice
  # GET /questions/compute_tips/:question_id
  def compute_tips
    question = Question.find(params[:id])
    question.compute_tips
    redirect_to edit_question_path(question)
  end
  
  # this is a rjs  
  # GET /questions/toggle_is_multiple/1
  def toggle_is_multiple
    question = Question.find(params[:id])
    question.update_attribute(:is_multiple, !(question.is_multiple))
    render :update do |page|   
    end
  end
  
  # this is a rjs  
  # display or not the question's background media
  # GET /questions/toggle_display_background_media/1
  def toggle_display_background_media
    question = Question.find(params[:id])
    question.update_attribute(:display_background_media, !(question.display_background_media))
    render :update do |page|   
    end
  end
  
  # this is a rjs  
  # display or not the question's image background
  # GET /questions/toggle_display_background_image/1
  def toggle_display_background_image
    question = Question.find(params[:id])
    question.update_attribute(:display_background_image, !(question.display_background_image))
    render :update do |page|   
    end
  end
  
  # this is a rjs  
  # display or not the choice's thumbnail
  # GET /questions/toggle_display_thumbnail/1
  def toggle_display_thumbnail
    question = Question.find(params[:id])
    question.update_attribute(:display_thumbnail, !(question.display_thumbnail))
    render :update do |page|   
    end
  end

  # this is a rjs  
  # display or not the choice's media
  # GET /questions/toggle_display_choice_media/1
  def toggle_display_choice_media
    question = Question.find(params[:id])
    question.update_attribute(:display_choice_media, !(question.display_choice_media))
    render :update do |page|   
    end
  end
  
  # this is a rjs  
  # display or not the choice's title
  # GET /questions/toggle_display_title/1
  def toggle_display_title
    question = Question.find(params[:id])
    question.update_attribute(:display_title, !(question.display_title))
    render :update do |page|   
    end
  end
  
  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question = Question.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(questions_url) }
      format.xml  { head :ok }
    end
  end
  
  # add a choice to a question
  def add_choice
    question = Question.find(params[:id])
    question.add_choice(current_user)
    redirect_to(edit_question_path(question))
  end
  
  # change the state of a question      
  # /questions/:id/change_state/:state
  def change_state
    question = Question.find(params[:id])
    event_method = params[:state]
    question.send(event_method)
    question.change_state_callback(event_method)
    redirect_to("/categories/#{question.category_id}/questions")
  end
  

  
end
