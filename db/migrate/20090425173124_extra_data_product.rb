class ExtraDataProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :data_carriers, :string
    add_column :products, :data_rating, :integer
    add_column :products, :data_price, :string
  end

  def self.down
    remove_column :products, :data_carriers
    remove_column :products, :data_rating
    remove_column :products, :data_price
  end
end
