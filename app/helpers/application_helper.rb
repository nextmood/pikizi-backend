# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  
  # ===================================================================================
  # Utilities
  
  def box_title(options = nil)
    "<div class=\"box\" #{options}>
        <h1 class=\"box_header\">"
  end
  
  def box_content(options = nil)
    "</h1><div class=\"box_content\" #{options}>"
  end
  
  def box_end
    "</div></div>"
  end
    
  def format_date(date) date ? date.strftime("%a %m/%d %H:%M") : "-" end
  
  def as_percentage(x,y)
    x,y = x.to_f, y.to_f
    (y == 0.0) ? "n/a" : ("%3d"  % (x * 100 / y) << "%")
  end
  
  # display a select of objects (some of them selected), using the "method" to get a string for the object
  # options are:
  # :multiple -> to allow multiple selection
  # :onclick_url -> a url when a value is clicked
  # :compare_with_id -> lambda(fonction to compare if object is selected)
  def fpa_select_helper(name, objects, objects_selected, method, options= {})
    dom_id = "dom_#{name}"
    objects_selected ||= []
    objects_selected = [objects_selected] unless objects_selected.is_a?(Array)
    raise "you can't select more than one object" unless options[:multiple] or objects_selected.size <=1
    option_multiple = nil
    if options[:multiple]
      name = "#{name}[]"
      option_multiple = "multiple=\"true\""
    end

    options[:style] = "style=\"#{options[:style]}\"" if options[:style]
    
  	s = "<select id=\"#{dom_id}\" name=\"#{name}\" #{option_multiple} #{options[:style]}>"
  	objects.each { |object| 
  	  s << "<option value=\"#{object.id}\""
  	  
  	  s << " selected=\"selected\"" if (options[:compare_with_id] ? objects_selected.include?(object.id) : objects_selected.include?(object))
  	  s << ">#{object.send(method)}</option>"
  	}
  	s << "</select>"
  	if options[:onclick_url]
  	  s << observe_field( dom_id,
                          :url => "#{options[:onclick_url]}",
                          :frequency => 0.5,
                          :with => "?tag_id=document.getElementById('#{dom_id}').value")
    end
    s
  end
      	
  # ===================================================================================  
    
  def compute_draggable_id(product_id, question_id) "dgp_#{product_id}.#{question_id}" end
  
    
  SEPARATOR_MENU = '&nbsp;|&nbsp;'
  TAG_MENU_CURRENT = "selected=\"true\""
  
  def menu_item(url, title, options = {})
    options[:title] ||= title
    "#{options[:no_separator] ? '' : SEPARATOR_MENU}<a #{@controller.request.path.start_with?(url)  ? TAG_MENU_CURRENT : ''} href=\"#{url}\" title=\"#{options[:title]}\">#{title}</a>"
	end

	  
end
