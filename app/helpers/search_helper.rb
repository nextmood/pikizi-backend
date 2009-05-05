module SearchHelper


  def link_to_search(category, class_name)
    s = "<div class=\"#{class_name} category_node\" style=\"position:relative;\">"
    s << link_to_remote(category.label, 
                        :url => {:controller => "search", :action => "search_in_category", :category_id => category.id },
                        :html => {:style => "position:absolute; left:0px; top:0px;  padding:2px;"})
    if category.children.size > 0
      s << "<div style=\"position:absolute; right:0px; bottom:0px; padding:2px;\">"
      s << link_to_remote("more...", :url => {:controller => "search", :action => "change_category", :category_id => category.id })
      s << "</div>"
    end
    s << "</div>"
    s
  end

  # parametrs of the search box (in session)
  def search_box_parameters(title_symbol) session[:search_box_parameters][title_symbol] end

  

  
end