class Addquizz < ActiveRecord::Migration
  def self.up
    add_column :categories, :default_quiz_id, :integer
  end

  def self.down
    remove_column :categories, :default_quiz_id
  end
end
