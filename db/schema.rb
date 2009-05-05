# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090425173124) do

  create_table "categories", :force => true do |t|
    t.string   "label"
    t.string   "path"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_url"
    t.string   "image_filename"
    t.integer  "default_quiz_id"
  end

  add_index "categories", ["parent_id"], :name => "index_categories_on_parent_id"

  create_table "choices", :force => true do |t|
    t.integer  "question_id"
    t.integer  "author_id"
    t.string   "type"
    t.string   "code"
    t.string   "label"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_url"
    t.integer  "feature_id"
    t.integer  "product_id"
    t.integer  "index"
    t.string   "extract"
    t.integer  "feature_value_id"
    t.string   "image_filename"
    t.string   "product_filters_operator", :default => "or"
  end

  create_table "collections", :force => true do |t|
    t.integer  "wishlist_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "collections", ["product_id"], :name => "index_collections_on_product_id"
  add_index "collections", ["wishlist_id"], :name => "index_collections_on_wishlist_id"

  create_table "domains", :force => true do |t|
    t.string   "type"
    t.string   "descriptor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feature_id"
    t.integer  "cardinality"
  end

  create_table "dtags", :force => true do |t|
    t.string   "label"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_url"
    t.integer  "index",          :default => 0
    t.integer  "domain_id"
    t.string   "image_filename"
  end

  create_table "feature_reviews", :force => true do |t|
    t.integer  "feature_value_id"
    t.float    "rating"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extract"
    t.float    "weight",                  :default => 0.5
    t.integer  "product_id"
    t.integer  "feature_id"
    t.integer  "review_id"
    t.string   "better_than_product_ids"
    t.string   "same_product_ids"
    t.string   "worse_than_product_ids"
  end

  create_table "feature_values", :force => true do |t|
    t.integer  "feature_id"
    t.integer  "product_id"
    t.string   "value",                    :limit => 1024
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extract"
    t.float    "weight",                                                                  :default => 0.5
    t.integer  "author_id"
    t.string   "url"
    t.string   "media_url"
    t.float    "average_rating"
    t.integer  "is_hot_cold",                                                             :default => 0
    t.string   "image_filename"
    t.integer  "rating_average_user",      :limit => 10,   :precision => 10, :scale => 0, :default => 0
    t.integer  "rating_average_automatic", :limit => 10,   :precision => 10, :scale => 0, :default => 0
    t.integer  "rating_average_combined",  :limit => 10,   :precision => 10, :scale => 0, :default => 0
  end

  create_table "features", :force => true do |t|
    t.integer  "category_id"
    t.string   "type"
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "extract"
    t.string   "semantic_category"
    t.float    "weight",                :default => 0.5
    t.integer  "author_id"
    t.string   "media_url"
    t.string   "label"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "url"
    t.integer  "domain_id"
    t.boolean  "auto_recommendation",   :default => true
    t.boolean  "is_hidden",             :default => false
    t.string   "image_filename"
    t.integer  "automatic_rating_mode", :default => 0
  end

  create_table "friendships", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.integer  "friend_id",   :null => false
    t.datetime "created_at"
    t.datetime "accepted_at"
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["user_id"], :name => "index_friendships_on_user_id"

  create_table "mappers", :force => true do |t|
    t.integer "category_id"
    t.string  "pattern_full"
    t.string  "pattern_value"
    t.integer "feature_id"
  end

  create_table "product_filters", :force => true do |t|
    t.integer  "feature_id"
    t.string   "type"
    t.string   "descriptor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "choice_id"
    t.integer  "recommendation", :default => 0
    t.integer  "product_id"
    t.string   "operator",       :default => "or"
  end

  create_table "product_similarities", :force => true do |t|
    t.integer  "product_id"
    t.integer  "similar_product_id"
    t.float    "similarity",         :default => 0.0
    t.float    "confidence",         :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_similarities", ["product_id"], :name => "index_product_similarities_on_product_id"
  add_index "product_similarities", ["similar_product_id"], :name => "index_product_similarities_on_similar_product_id"

  create_table "products", :force => true do |t|
    t.string   "label"
    t.string   "url"
    t.string   "state"
    t.integer  "category_id"
    t.string   "category_path"
    t.integer  "author_id"
    t.text     "description"
    t.string   "filename_image_small"
    t.string   "filename_image_big"
    t.string   "amazon_asin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "media_url"
    t.float    "average_rating"
    t.string   "image_filename"
    t.integer  "rating_average_user",      :limit => 10, :precision => 10, :scale => 0, :default => 0
    t.integer  "rating_average_automatic", :limit => 10, :precision => 10, :scale => 0, :default => 0
    t.integer  "rating_average_combined",  :limit => 10, :precision => 10, :scale => 0, :default => 0
    t.string   "data_carriers"
    t.integer  "data_rating"
    t.string   "data_price"
  end

  add_index "products", ["amazon_asin"], :name => "index_products_on_amazon_asin"
  add_index "products", ["author_id"], :name => "index_products_on_author_id"
  add_index "products", ["category_id"], :name => "index_products_on_category_id"
  add_index "products", ["state"], :name => "index_products_on_state"

  create_table "questions", :force => true do |t|
    t.string   "type"
    t.string   "url"
    t.string   "state",                     :default => "draft"
    t.integer  "author_id"
    t.integer  "category_id"
    t.integer  "manual_priority",           :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label"
    t.string   "media_url"
    t.boolean  "is_public",                 :default => true
    t.boolean  "display_thumbnail",         :default => false
    t.boolean  "display_title",             :default => true
    t.boolean  "is_multiple",               :default => true
    t.string   "extract"
    t.string   "image_filename"
    t.boolean  "display_background_image",  :default => false
    t.boolean  "display_background_media",  :default => false
    t.boolean  "display_choice_media",      :default => false
    t.integer  "tip_tag_id"
    t.integer  "tip_product_filter_yes_id"
    t.string   "tip_label"
    t.integer  "feature_id"
    t.integer  "feature_value_id"
    t.integer  "feature_value_1_id"
    t.integer  "feature_value_2_id"
    t.boolean  "is_compensatory",           :default => true
  end

  create_table "quiz_instances", :force => true do |t|
    t.integer  "quiz_id"
    t.integer  "user_id"
    t.string   "session_id"
    t.integer  "nb_questions_answered"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "quiz_instances", ["quiz_id"], :name => "index_quiz_instances_on_quiz_id"
  add_index "quiz_instances", ["session_id"], :name => "index_quiz_instances_on_session_id"
  add_index "quiz_instances", ["user_id"], :name => "index_quiz_instances_on_user_id"

  create_table "quiz_products", :force => true do |t|
    t.integer "quiz_id"
    t.string  "product_id"
  end

  add_index "quiz_products", ["product_id"], :name => "index_quiz_products_on_product_id"
  add_index "quiz_products", ["quiz_id"], :name => "index_quiz_products_on_quiz_id"

  create_table "quiz_questions", :force => true do |t|
    t.integer "quiz_id"
    t.string  "question_id"
  end

  add_index "quiz_questions", ["question_id"], :name => "index_quiz_questions_on_question_id"
  add_index "quiz_questions", ["quiz_id"], :name => "index_quiz_questions_on_quiz_id"

  create_table "quizzes", :force => true do |t|
    t.string   "type"
    t.integer  "author_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
    t.string   "label"
    t.string   "extract"
    t.string   "media_url"
    t.string   "image_filename"
  end

  create_table "rates", :force => true do |t|
    t.integer  "user_id"
    t.integer  "rateable_id"
    t.string   "rateable_type"
    t.integer  "stars"
    t.string   "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rates", ["rateable_id"], :name => "index_rates_on_rateable_id"
  add_index "rates", ["user_id"], :name => "index_rates_on_user_id"

  create_table "reviews", :force => true do |t|
    t.integer  "product_id"
    t.integer  "author_id"
    t.float    "author_weight"
    t.integer  "rating"
    t.string   "url"
    t.text     "amazon_data"
    t.string   "summary"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  add_index "reviews", ["author_id"], :name => "index_reviews_on_author_id"
  add_index "reviews", ["product_id"], :name => "index_reviews_on_product_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "tips", :force => true do |t|
    t.integer  "product_id",        :null => false
    t.integer  "choice_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_filter_id"
    t.integer  "recommendation"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                        :limit => 40
    t.string   "name",                         :limit => 100, :default => ""
    t.string   "email",                        :limit => 100
    t.string   "crypted_password",             :limit => 40
    t.string   "salt",                         :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",               :limit => 40
    t.datetime "remember_token_expires_at"
    t.integer  "expert_in_category_id"
    t.integer  "wishlist_current_id"
    t.integer  "user_zip_code",                               :default => 0
    t.integer  "user_age",                                    :default => 0
    t.integer  "user_income",                                 :default => 0
    t.integer  "user_gender",                                 :default => 0
    t.integer  "user_state",                                  :default => 0
    t.integer  "user_country",                                :default => 0
    t.integer  "user_agree_with_terms_of_use",                :default => 0
    t.integer  "user_wants_private_data",                     :default => 1
    t.boolean  "dont_send_email",                             :default => false
    t.string   "roles",                                       :default => ""
    t.float    "weight",                                      :default => 1.0
    t.string   "amazon_customerid",            :limit => 40
    t.boolean  "is_automatic",                                :default => false
    t.string   "media_url"
    t.string   "image_filename"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "wishlists", :force => true do |t|
    t.integer  "owner_id"
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wishlists", ["owner_id"], :name => "index_wishlists_on_owner_id"

end
