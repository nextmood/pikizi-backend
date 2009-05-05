
class ProductFiltersController < ApplicationController

  # /product_filters/update_product_filter/15" with {:method=>:post}):
  # this is a RJS
  def update_product_filter
    product_filter = ProductFilter.find(params[:id])
    definition = params[:definition]
    
    # lleanning up datas
    definition[:earlier] = Date.new(Integer(definition[:earlier][:year]), Integer(definition[:earlier][:month]), Integer(definition[:earlier][:day])) if definition[:earlier]
    definition[:latest] = Date.new(Integer(definition[:latest][:year]), Integer(definition[:latest][:month]), Integer(definition[:latest][:day])) if definition[:latest]
    
    definition[:min] = Float(definition[:min]) if definition[:min]
    definition[:max] = Float(definition[:max]) if definition[:max]
    definition[:tag_ids] = definition[:tag_ids].collect { |tag_id|  Integer(tag_id) } if definition[:tag_ids]
    
    product_filter.update_definition(definition)
    render :update do |page|
      page.replace_html("product_filter_#{product_filter.id}_updated_at", " @ #{Time.now.to_s}")
    end
    
  end

end