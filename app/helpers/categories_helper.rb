module CategoriesHelper
  
  
  def categories_selector(object="product", field="category_id", selected_value = nil, error_message = nil, new_category = false)
    s =  "<select id=\"#{object}_#{field}\" name=\"#{object}[#{field}]\" class=\"editable_value\">"
    s << options_from_collection_for_select(Category.root.self_and_descendants[1..10000], "id", "path_without_root", selected_value) if Category.root
    s << "</select>"
    s << "&nbsp;or&nbsp;" << text_field_tag('new_category_label', nil, :size => 15, :class => "editable_value") if new_category
    s
  end
  
  def categories_selector_with_new(object="product", field="category_id", selected_value = nil, error_message = nil)
    categories_selector(object, field, selected_value, error_message, true)
  end

  def categories_ancestor_and_self_selector(name, category)
    s =  "<select id=\"#{name}\">"
    s << options_from_collection_for_select(category.self_and_ancestors, "id", "path", category.id)
    s << "</select>"
    s
  end
  
  def category_dom_id(category_id) "category_#{category_id}" end
  
end
