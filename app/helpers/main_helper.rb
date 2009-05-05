module MainHelper

  def color_of_state(state)
	  state = state.to_s
	  case state
      when "draft" then "lightblue"
      when "published_test" then "yellow"
      when "published" then "lightgreen"
      when "trashed" then "red"
      else "grey"
    end  
	end

  
end