module ProductFiltersHelper

  # a dom id for a domain
  def product_filter_dom_id(product_filter_id) "product_filter_#{product_filter_id}" end
      
  def product_filter_label(product_filter, options={})
    if options[:display]
      line_break = options[:line_break] ? "<br/" : ""
      if product_filter
        the_feature = product_filter.feature
        the_product = product_filter.product
        label = if product_filter.is_a?(ProductFilterFeature)
                  "<b>#{the_feature ? the_feature.path : 'no feature !'}</b>&nbsp;"
                elsif product_filter.is_a?(ProductFilterSimple)
                  "<b>#{the_product ? the_product.label : 'no product!'}</b>&nbsp;"
                elsif product_filter.is_a?(ProductFilterRating)
                  "<b>Rating:</b>#{the_feature ? the_feature.path : 'no feature !'}&nbsp;"
                else
                  nil
                end
        recommendation_tag =  case product_filter.recommendation
                                when 1 then "(ok)"
                                when -1 then "(ko)"
                                else 
                                  "(??=#{value})"
                              end      
        extra_info =  if product_filter.is_a?(ProductFilterFeatureNumeric) or product_filter.is_a?(ProductFilterFeatureDate)
                        if the_feature
                          "#{the_feature.domain.as_string(product_filter.descriptor[:min])} -- #{the_feature.domain.as_string(product_filter.descriptor[:max])}"
                        else
                          "??????????????"
                        end
                      else
                        nil
                      end
        
      
        "#{label}#{recommendation_tag}#{extra_info}#{line_break}"
      else
        "no product filter ! #{line_break}"
      end
    end
  end
  
end