class Background < ActiveRecord::Migration
  
  def self.up
    add_column :questions, :display_background_image, :boolean, :default => false
    add_column :questions, :display_background_media, :boolean, :default => false
    add_column :questions, :display_choice_media, :boolean, :default => false
    add_column :questions, :tip_tag_id, :integer, :default => nil
    add_column :questions, :tip_product_filter_yes_id, :integer, :default => nil
    add_column :questions, :tip_label, :string, :default => nil
    add_column :questions, :feature_id, :integer, :default => nil
    add_column :questions, :feature_value_id, :integer, :default => nil
    rename_column :quizzes, :user_id, :author_id
    add_column :quizzes, :label, :string
    add_column :quizzes, :extract, :string
    add_column :quizzes, :media_url, :string
    add_column :quizzes, :image_filename, :string
    rename_table :tags, :dtags
  end

  def self.down
    remove_column :questions, :display_background_image
    remove_column :questions, :display_background_media
    remove_column :questions, :display_choice_media
    remove_column :questions, :tip_tag_id
    remove_column :questions, :tip_product_filter_yes_id
    remove_column :questions, :tip_label
    remove_column :questions, :feature_id
    remove_column :questions, :feature_value_id
    rename_column :quizzes, :author_id, :user_id
    remove_column :quizzes, :label
    remove_column :quizzes, :extract
    remove_column :quizzes, :media_url
    remove_column :quizzes, :image_filename
    rename_table :dtags, :tags
  end
  
end
