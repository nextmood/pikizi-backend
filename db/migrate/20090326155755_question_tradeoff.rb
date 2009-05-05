class QuestionTradeoff < ActiveRecord::Migration
  def self.up
    add_column :questions, :feature_value_1_id, :integer
    add_column :questions, :feature_value_2_id, :integer
  end

  def self.down
    remove_column :questions, :feature_value_1_id
    remove_column :questions, :feature_value_2_id
  end
  
end
