class Search
  
  DEFAULT_SEARCH_LABEL = "Search or Browse categories"
  MAX_RESULTS = 10
  
  def self.default_label() DEFAULT_SEARCH_LABEL end
    
  # search for products from a string
  # using the ferret, and act as ferret mechanism
  # optional parameter: category_id to narrow the search
  def self.execute(search_string, category_id=nil)
    if category_id
      category = Category.find(category_id)
      descendants_and_self_ids = category.self_and_descendants.collect(&:id)
      filter_sql = "category_id IN (#{descendants_and_self_ids.join(',')})"
    else
      category = Category.root
      filter_sql = nil
    end
    
    products =  if search_string == "" or search_string == DEFAULT_SEARCH_LABEL
                  # search string empty !, send back the first MAX_RESULTS products
                  Product.find(:all, :limit => MAX_RESULTS, :conditions => filter_sql)
                else
                  Product.find_with_ferret(search_string, {:limit => MAX_RESULTS}, {:conditions => filter_sql} )
                end
    [products, category]
  end
  
end