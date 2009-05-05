class AmazonLookUpController < ApplicationController

  # Display the search box for Amazon
  def index
    @category = Category.find(params[:category_id])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Processing the search and output the results
  # this is a post
  def search
    @category = Category.find(params[:category_id])
    @query_string = params[:query_string]
    @list_records, @total_pages, @total_results, @item_page = ApiAmazon.get_amazon_products(@query_string)
    render(:controller => 'amazon_look_up', :action => 'index')
  end
  
  # Display an amzon product detail
  def details
    @category = Category.find(params[:category_id])
    asin = params[:asin]
    @amazon_product = ApiAmazon.get_amazon_product(asin)
  end
  

  
end
