class Mapper < ActiveRecord::Migration
  def self.up
    create_table :mappers, :force => true do |t|
      t.integer  :category_id
      t.string   :pattern_full
      t.string   :pattern_value
      t.integer  :feature_id
      t.timestamp
    end
    
  end

  def self.down
    drop_table :mappers
  end
end
