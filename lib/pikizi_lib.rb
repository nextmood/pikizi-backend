# lib functions
class PikiziLib
  
  def self.partition_increment(hash, key, field, value) 
	  h = hash[key]
	  h ||= (hash[key] = {})
	  if is_plurial(field)
	    h[field] = [] unless h[field]
      h[field] << value
    else
      h[field] = value
    end
  end
  
  def self.partition_flatten(hash, key_field, fields)
    hash.collect { |key, tupple| 
      result = {key_field => key}
      fields.collect { |field|  
        x = tupple[field]
        x = [] if x.nil? and is_plurial(field)
        result[field] = x if x
        }
      result
    } 
  end
  
  POSTFIX_PLURAL = 's'[0]
  def self.is_plurial(field) field[-1] == POSTFIX_PLURAL end
  
  def self.sql_to_list_of_ids(sql)
    ids = []
    res = ActiveRecord::Base.connection().execute(sql)
    while row = res.fetch_row do 
      ids << row[0]
    end
    ids
  end
  
  def self.clean_string(s) (s and s !="") ? s : nil end
  
  def self.copy_flex_image_path(from_object_dir, from_object_id, to_object_dir, to_object_id)
    #puts "copy if any ... from class=#{from_object_dir} ids=#{from_object_id.inspect} .... to  class=#{to_object_dir} id=#{to_object_id.inspect}"
    #execute("find ./uploaded_photos/#{from_object_dir} -name '#{from_object_id}.png' -print")
    #TODO
  end
  
end
