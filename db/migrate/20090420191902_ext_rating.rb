class ExtRating < ActiveRecord::Migration
  def self.up
    
    add_column :feature_values, :rating_average_user, :decimal, :default => 0
    add_column :feature_values, :rating_average_automatic, :decimal, :default => 0
    add_column :feature_values, :rating_average_combined, :decimal, :default => 0
    
    add_column :products, :rating_average_user, :decimal, :default => 0
    add_column :products, :rating_average_automatic, :decimal, :default => 0
    add_column :products, :rating_average_combined, :decimal, :default => 0
    
  end

  def self.down
    
    remove_column :feature_values, :rating_average_user
    remove_column :feature_values, :rating_average_automatic
    remove_column :feature_values, :rating_average_combined
    
    remove_column :products, :rating_average_user
    remove_column :products, :rating_average_automatic
    remove_column :products, :rating_average_combined
    
    
  end
end
