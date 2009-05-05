# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  # -------------------------------------------------------------------------
  # BEGIN Methods added by FPA (resetting password)
  # -------------------------------------------------------------------------
  
  def request_new_password
  end
  
  # function added by FPA
  def send_new_password
    email_or_login = params[:email_or_login]
    user = User.find_by_email(email_or_login)
    user ||= User.find_by_login(email_or_login)
    if user
      password = user.reset_random_password
      UserMailer.deliver_new_password(user, password) 
      @deliver_to_email = user.email            
    else
      flash[:error] = "There is no user linked to email or login: #{email_or_login}"
      render '/request_new_password'
    end
  end
  
  # -------------------------------------------------------------------------
  # END Methods added by FPA
  # -------------------------------------------------------------------------
  
protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end
