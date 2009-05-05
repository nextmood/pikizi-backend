class LogicalOperators < ActiveRecord::Migration
  
  def self.up
    add_column :choices, :product_filters_operator, :string, :default => "or"
    add_column :product_filters, :operator, :string, :default => "or"
    add_column :features, :automatic_rating_mode, :integer, :default => 0
  end

  def self.down
    remove_column :choices, :product_filters_operator
    remove_column :product_filters, :operator
    remove_column :features, :automatic_rating_mode
  end
  
end
