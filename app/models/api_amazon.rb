
require 'amazon/ecs'


class ApiAmazon
  
  # ====================================================================================================
  # Amazon Interface
  # Restriction
  # no more than one request per second
  # only to drive product purchase from amazon
  # ====================================================================================================
  
  # set the default options; options will be camelized and converted to REST request parameters.
  # Access Key ID =  1PR0S6RKJ4MHVNWDMK82  
  # Secret access key =  ddcdZLkvJ9YQpySTwJiVEbrZI7w2zPZxz1Uz/2fs  
  # see http://docs.amazonwebservices.com/AWSECommerceService/2008-04-07/DG/
  Amazon::Ecs.options = {:aWS_access_key_id => "1PR0S6RKJ4MHVNWDMK82" }
  Amazon::Ecs.debug = true
  AMAZON_STORE = "All" 
  NB_MAX_PAGES_REVIEW = 4
      
  def self.get_amazon_products(query_string)
    res = Amazon::Ecs.item_search(query_string, :type => "Keywords", :search_index => AMAZON_STORE, :response_group => 'Small')      
      
    list_records = []
    res.items.each do |item|
      list_records << { :asin => item.get(:asin),
                  :detail_page_url => item.get('detailpageurl'),
                  :manufacturer => item.get('itemattributes/manufacturer'),
                  :product_group => item.get('itemattributes/productgroup'),
                  :title => item.get('itemattributes/title') }
    end
        
    [list_records, res.total_pages, res.total_results, res.item_page]
  end
  
  def self.get_amazon_product(asin)
    res = Amazon::Ecs.item_lookup(asin, :response_group => 'Large')
    amazon_product = {}
    item = res.first_item
    amazon_product[:asin] = item.get('asin')
    amazon_product[:detail_page_url] = item.get('detailpageurl')
    amazon_product[:title] = item.get('itemattributes/title')
    amazon_product[:image] = item.get('largeimage/url')
    amazon_product[:product_group] = item.get('itemattributes/productgroup')
    amazon_product[:manufacturer] = item.get('itemattributes/manufacturer') 
    amazon_product[:released_on] = item.get('itemattributes/releasedate')
    amazon_product[:price] = item.get('itemattributes/listprice/amount') # $x 100
    amazon_product[:price] = amazon_product[:price].to_f / 100.0 if amazon_product[:price]
    
    amazon_product[:descriptions] = []
    if descriptions = item/'editorialreview'
      descriptions.each do |description|
        amazon_product[:descriptions] << { 
          :source => ApiAmazon.parse_amazon_element(description, 'source', :html), 
          :content => ApiAmazon.parse_amazon_element(description, 'content', :text) }
      end
    end
        
    amazon_product[:similar_products] = []
    if similar_products = item/'similarproduct'
      similar_products.each do |similar_product|
        amazon_product[:similar_products] << { 
            :asin => ApiAmazon.parse_amazon_element(similar_product, 'asin', :html),
            :title => ApiAmazon.parse_amazon_element(similar_product, 'title', :html) }
      end
    end
    
    amazon_product
  end
  
  # Retrieve all reviews for a given ASIN  
  def self.get_amazon_reviews(asin, page_index=1)
    res = Amazon::Ecs.item_lookup(asin, :review_page => page_index, :response_group => 'Reviews')
    item = res.first_item
    total_nb_pages = item.get('customerreviews/totalreviewpages').to_i
    amazon_reviews = []
    if reviews = item/'review'
      reviews.each do |review|
        amazon_reviews << {
          :rating => ApiAmazon.parse_amazon_element(review,'rating', :html),
          :helpfulvotes =>  ApiAmazon.parse_amazon_element(review,'helpfulvotes', :html),
          :customerid => ApiAmazon.parse_amazon_element(review,'customerid', :html),
          :totalvotes => ApiAmazon.parse_amazon_element(review,'totalvotes', :html),
          :date => ApiAmazon.parse_amazon_element(review,'date', :html),
          :summary => ApiAmazon.parse_amazon_element(review,'summary', :html),
          :content => ApiAmazon.parse_amazon_element(review,'content', :text)
        }
      end
      amazon_reviews.concat(ApiAmazon.get_amazon_reviews(asin, page_index+1)) if page_index < total_nb_pages and page_index < NB_MAX_PAGES_REVIEW
    end
    amazon_reviews
  end



  # create a new set of reviews (and users) from amazon catalog
  def self.create_new_reviews_from_amazon(product)
    amazon_reviews = ApiAmazon.get_amazon_reviews(product.amazon_asin)
    amazon_reviews.each { |amazon_review| 
        
        customer_id = amazon_review[:customerid]
        user_amazon = User.find_by_amazon_customerid(customer_id)
        user_amazon ||= User.automatic_creation("amazon_cust_#{customer_id}", nil, {:amazon_customerid => customer_id, :expert_in_category_id => product.category_id})
        
        product.create_review(user_amazon, {:created_at => amazon_review[:date],
                                           :rating => amazon_review[:rating],
                                           :summary => amazon_review[:summary],
                                           :content => amazon_review[:content],
                                           :amazon_data => { :helpfulvotes => amazon_review[:helpfulvotes],
                                                             :totalvotes => amazon_review[:totalvotes] }
                                           })
    }
    amazon_reviews.size
  end
  
  # 
  def self.create_new_product_from_amazon(asin, author, category_id)
    error = nil
    product = nil
    begin
      amazon_product = ApiAmazon.get_amazon_product(asin)
      category = Category.find(category_id)
      product = category.add_new_default_product(amazon_product[:title], author)
      product.update_attributes(:url => amazon_product[:detail_page_url],
                                :description => amazon_product[:descriptions].collect { |description| description[:content] }.join,
                                :amazon_asin => asin,
                                :image_file_url => amazon_product[:image])
    rescue Exception => e 
      error = e.to_s
      product.destroy if product
    end
    
    # FPA: Horrible hack
    # 1, 2 and 3 and the feature_id of the brand, price, release etc...
    # one should write a mapper between an external source and the wikiproduct
    # see mapper object
    unless error
      begin
        product.set_value(1, amazon_product[:manufacturer]) if amazon_product[:manufacturer]
        product.set_value(2, [amazon_product[:price], amazon_product[:price]]) if amazon_product[:price]
        product.set_value(3, amazon_product[:released_on]) if amazon_product[:released_on]
        #product.set_value("group", amazon_product[:product_group])
      rescue
      end
    end
 
    [product, error]
  end
  
  protected
  
  def self.parse_amazon_element(node, tag, inner)
    if elt = node.at(tag)
      case inner
        when :html then elt.inner_html
        when :text then elt.inner_text
      end
    end
  end
  
end
