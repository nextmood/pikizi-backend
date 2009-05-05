module QuestionsHelper
  
  def question_dom_id(question_id) "question_#{question_id || 'new'}" end
	   
  def question_sentence(question, choice_selected=nil)
    choice_labels = question.choices.collect { |choice| choice_selected == choice ? "<b>#{choice.label}</b>" : choice.label }
    "#{question.label} [#{choice_labels.join(', ')}]"
  end
  
   
  def ar_field_editor(ar_object, ar_field, label, options = {})
    ar_field_value = ar_object.send(ar_field)
    has_a_value = (ar_field_value and ar_field_value != "" and ar_field_value != [])
    ar_field_value = ar_field_value.join(', ') if ar_field_value.is_a?(Array)
    dom_id = "dom_edit_#{ar_object.class}_#{ar_object.id}_#{ar_field}"
    if ar_object.is_a?(Question)
      options[:url] = "/questions/set_question_#{ar_field}/#{ar_object.id}"
    elsif ar_object.is_a?(Choice)
      options[:url] = "/choices/set_choice_#{ar_field}/#{ar_object.id}"
    else
      raise "error"
    end
    editor = in_place_editor(dom_id, options)
    "<div style=\"margin-bottom:0px;\">
        #{label}:
        <span id=\"#{dom_id}\" class=\"editable_value\">#{has_a_value ? ar_field_value : '...'}</span>
        #{editor}
     </div>"
  end

	
	def question_state(question, with_div=true)
  	next_actions = question.get_next_possible_events.collect { |label, event| 
  		                link_to(label, "/questions/#{question.id}/change_state/#{event}")
  		             }
  	s = "&nbsp;status:
     		  <span style=\"background-color:#{color_of_state(question.current_state)}\">
     		    #{question.current_state}
     		  </span>&nbsp;
     		  #{next_actions.join(', ')}"
    
    with_div ? "<div style=\"margin-bottom:10px;\">#{s}</div>" : s
    
	end
	
end
