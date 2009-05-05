# --------------------------------------------------------------------------------------
# Plugin restful authorisation
# --------------------------------------------------------------------------------------

require 'digest/sha1'
require 'pikizi_lib'

class User < ActiveRecord::Base
  
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

#  before_create :make_activation_code
  
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  
  attr_accessible :login, :email, :name, :password, :password_confirmation
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  
  # -------------------------------------------------------------------------
  # BEGIN Methods added by FPA
  # -------------------------------------------------------------------------
  
  has_many :authored_reviews, :foreign_key => "author_id", :class_name => "Review"
  has_many :authored_questions, :foreign_key => "author_id", :class_name => "Question"
  has_many :authored_products, :foreign_key => "author_id", :class_name => "Product"  
  belongs_to  :wishlist_current, :class_name => "Wishlist", :foreign_key => "wishlist_current_id"
  belongs_to  :expert_in_category, :class_name => "Category", :foreign_key => "expert_in_category_id"
  has_many   :wishlists
  
  # plugin ajaxful rating
  ajaxful_rater
  
	
  # Create a user from a login
  # email is not mandatory
  #
  def self.automatic_creation(login, email = nil, fields = {})
    email ||= "#{login}@unknown.com"
    user = User.create(:login => login, :email => email, :password => login, :password_confirmation => login, :is_automatic => true)
    raise "error user (login=#{login})not created #{user.errors.inspect}" unless user.id
    user.update_attributes(fields)
    user.set_default_roles_for_new_user
    user
  end
  
  # Reset a user password
  def reset_random_password
    new_passord = "W#{1000 + rand(999)}"
    new_passord[0] = rand(10) + 64
    self.update_attributes(:password => new_passord, :password_confirmation => new_passord)
    new_passord
  end
  
  # default user system
  def self.get_user_system() @@user_system ||= User.find_by_login("system") end
    
  # define a name to use on screen
  def screen_name
    (self.name and self.name != "") ? self.name : (self.amazon_customerid ? "a amazon user" : self.login)
  end
    
  # define the profile data
  # see also methods in UserHelper
  PROFILE_DATA = { :user_age => {:label => 'Age bracket',
                                 :domain => [[0, "?"], [10, "less than 18"], [20, "18-25"], [30, "26-34"], [40, "35-44"], [50, "45-54"], [60, "55-64"], [70, "65 and older"]] },
                   :user_income => {:label => 'Income bracket',
                                    :domain =>[[0, "?"], [10, "less than $20,000/year"], [20, "$20,000 to $50,000/year"], [30, "$50,000 to $80,000/year"], [40, "$80,000 to $120,000/year"], [50, "$120,000 to $160,000/year"], [60, "Over $160,000/year"]] }
                  }                  
  PROFILE_DATA.each_key { |name|  attr_accessible name }                    
  attr_accessible :expert_in_category_id, :is_automatic
  
  def self.profile_data() PROFILE_DATA end

  
  
  # --------------------------------------------------------------------------------------
  # FPA to add an image for the user
  # see http://github.com/Squeegy/fleximage/tree/master
  # --------------------------------------------------------------------------------------
  
  attr_accessible :image_file, :image_file_url
  
  acts_as_fleximage do
    image_directory 'uploaded_photos/user'
    require_image false
    default_image_path "public/images/default/default_user.png" 
  end
  
  # --------------------------------------------------------------------------------------
  # FPA Role management
  # --------------------------------------------------------------------------------------
   
  ROLES_NAME = [ROLE_NAME_SESSION = "session", "administrator", ROLE_NAME_USER = "user", "manufacturer"]

  serialize :roles
  
  def self.all_roles() ROLES_NAME end
    
  def self.check_role(user, role_name) 
    user ? (user.roles and user.roles.include?(role_name)) : (role_name == ROLE_NAME_SESSION)
  end
  
  def set_default_roles_for_new_user() self.roles = [ROLE_NAME_SESSION, ROLE_NAME_USER] end
  
  def update_roles(selected_roles) self.roles = selected_roles end
  
  # destroy all objects authored by this author
  def destroy_all_draft() 
  	# 
  end
    	
  # -------------------------------------------------------------------------
  # END Methods added by FPA
  # -------------------------------------------------------------------------

    

end
