class Absolute < ActiveRecord::Migration
  def self.up
    add_column :questions, :is_compensatory, :boolean, :default => true
  end

  def self.down
    remove_column :questions, :is_compensatory
  end
end
