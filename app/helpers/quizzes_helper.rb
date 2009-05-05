module QuizzesHelper
  
  def quiz_field_editor(quiz, ar_field, label, options = {})
    ar_field_value = quiz.send(ar_field)
    has_a_value = (ar_field_value and ar_field_value != "" and ar_field_value != [])
    ar_field_value = ar_field_value.join(', ') if ar_field_value.is_a?(Array)
    dom_id = "dom_edit_#{quiz.class}_#{quiz.id}_#{ar_field}"
    options[:url] = "/quizzes/set_quiz_#{ar_field}/#{quiz.id}"
    editor = in_place_editor(dom_id, options)
    "<div style=\"margin-bottom:0px;\">
        #{label}:
        <span id=\"#{dom_id}\" class=\"editable_value\">#{has_a_value ? ar_field_value : '...'}</span>
        #{editor}
     </div>"
  end
  
end
