require 'mysql'

class SqlRequest
  
  # Methods below ensure the creation of the new database (pikizi_development) from the old existing database 
  # (election008_development)
  
  DEFAULT_AUTHOR_ID = 62970
  CANDIDATES_IDS = "(62950, 62951, 62955, 62956, 62963)"
  
  def self.reset_database()
    @@from_sql_connection = Mysql.real_connect("127.0.0.1", "root", "sarah9", "election008_development")
                                                                         
    SqlRequest.copy_table("nm_contents.id, nm_contents.created_at, nm_contents.created_at, nm_contents.topic_1_id, nm_contents.url, nm_contents.author_profile_id, nm_contents.questionnaire_id, GROUP_CONCAT(nm_content_tags.tag_id), manual_priority
                           FROM nm_contents
                           LEFT OUTER JOIN nm_content_tags ON nm_content_tags.content_id = nm_contents.id
                           GROUP BY nm_contents.id", 
                           "statements", 
                           ["id", "created_at", "updated_at", "category_id", "url", "author_id", "category_id", "tags_ids", "manual_priority"])
                                                                  
    SqlRequest.copy_table(" nm_profiles.id, 
                            nm_profiles.created_at, 
                            IF(nm_users.email IS NULL, nm_profiles.session_system_name, nm_users.email),
                            CONCAT('Select2008:',nm_profiles.id)
                            FROM nm_profiles
                            LEFT OUTER JOIN nm_users ON nm_profiles.user_id = nm_users.id
                            INNER JOIN nm_votes ON nm_profiles.id = nm_votes.profile_id
                            GROUP BY nm_profiles.id", 
                           "profiles", 
                           ["id", "created_at", "label", "custom_profile_id"])  
    SqlRequest.create_podium_table
    SqlRequest.copy_table("content_id, content_before_id, button_code FROM nm_befores", 
                           "befores", 
                           ["statement_id", "statement_before_id", "button_code"])
                             
    SqlRequest.copy_table("content_1_id, content_2_id, weight FROM nm_equivalences", 
                                    "equivalences", 
                                    ["statement_1_id", "statement_2_id", "weight"])                               
    SqlRequest.copy_table("id, IF(parent_id = 0, NULL, parent_id), label, questionnaire_id, #{DEFAULT_AUTHOR_ID} FROM nm_topics", 
                                    "categories", 
                                    ["id", "parent_id", "label", "category_id", "author_id"]) 
    SqlRequest.copy_table("id, label, label, 'TagStatement' FROM nm_tags", 
                                    "tags", 
                                    ["id", "label", "type"])   
    SqlRequest.copy_table("content_id, created_at, profile_id, #{DEFAULT_AUTHOR_ID}, button_code FROM nm_votes WHERE profile_id IN #{CANDIDATES_IDS}", 
                                   "positions", 
                                   ["statement_id", "created_at", "product_id", "author_id", "button_code"])   
    SqlRequest.copy_table("content_id, created_at, profile_id, button_code, ip_address FROM nm_votes WHERE profile_id NOT IN #{CANDIDATES_IDS}", 
                                  "votes", 
                                  ["statement_id", "created_at", "profile_id", "button_code", "ip_address"])
    puts "reset table done"    
    @@from_sql_connection.close                       
  end
 
  # Everything below is protected
    
  protected
  
  FORBIDEN_CHAR_URL = ["'", "\\", "\"", "?", " ", "/"]
  def self.cleanup_url(s)
    FORBIDEN_CHAR_URL.each { |char| s.gsub!(char, "_") }
    s
  end
      
  def self.copy_table(from_select, to_table_name, to_fields_names)
    puts "erase table: #{to_table_name}"
    ActiveRecord::Base.connection().delete("DELETE FROM #{to_table_name}")
    puts "copying table: #{to_table_name} (SELECT #{from_select})"
    res = @@from_sql_connection.query("SELECT #{from_select}")
    while row = res.fetch_row do 
      field_sql = []
      for i in 0..(to_fields_names.size - 1)
        row[i] = SqlRequest.cleanup_url(row[i]) if to_fields_names[i] =~ /url/
        field_sql << "#{to_fields_names[i]}='#{SqlRequest.cleanup_string_for_sql(row[i])}'"
      end
      ActiveRecord::Base.connection().insert("INSERT INTO  #{to_table_name} SET #{field_sql.join(',')}")
    end
  end
  
  def self.cleanup_string_for_sql(s)
    SqlRequest.cleanup_string_bis(s, ["\\", "'"]) if s
  end
  
  def self.cleanup_string_bis(s, list_replace)
    list_replace.each { |replace|
      s.gsub!(replace,"\\@FPA@")
      s.gsub!("@FPA@",replace)
        }
    s
  end
  
  def self.create_podium_table
    puts "erase table: podia"
    ActiveRecord::Base.connection().delete("DELETE FROM podia")
    SqlRequest.create_podium_table_bis(1)
    #SqlRequest.create_podium_table_bis(2) # we don't create friends podium
  end
  
  def self.create_podium_table_bis(mode_candidate_friend)
    puts "creating table nm_podiums for mode #{mode_candidate_friend}"
    res = @@from_sql_connection.query("SELECT profile_fan_id, GROUP_CONCAT(profile_mentor_id) FROM nm_correlations  WHERE mode_candidate_friend=#{mode_candidate_friend} GROUP BY profile_fan_id")
    hash_podium = {}
    while row = res.fetch_row do 
      profile_fan_id = row[0]
      candidate_ids_string = row[1]
      # check if each profile exist
      candidates_ids_list = []
      candidates_labels_list = []
      candidate_ids_string.split(',').sort!.each { |candidate_id|  
          res_label = ActiveRecord::Base.connection().execute("SELECT label FROM profiles WHERE id=#{candidate_id}")
          row_label = res_label.fetch_row
          if row_label and not candidates_ids_list.include?(candidate_id)
            candidates_ids_list << candidate_id
            candidates_labels_list << row_label[0]
          end
        }
      if candidates_ids_list.size > 0
        candidates_ids_string = candidates_ids_list.join(',')
        if hash_podium[candidates_ids_string]
          hash_podium[candidates_ids_string][:fan_ids] << profile_fan_id
        else
          hash_podium[candidates_ids_string] = {:fan_ids => [profile_fan_id], :label => candidates_labels_list.join(', ') }
        end
      end
    end
    hash_podium.each { |candidates_ids_string, sub_hash|
      # retrieve the name of the candidates
      ActiveRecord::Base.connection().insert("INSERT INTO  podia SET label=\"#{sub_hash[:label]}\", candidate_ids=\"#{candidates_ids_string}\"")
      res = ActiveRecord::Base.connection().execute("SELECT id FROM podia WHERE candidate_ids=\"#{candidates_ids_string}\"")
      podium_id = res.fetch_row[0]
      sub_hash[:fan_ids].each { |profile_fan_id|  
        puts "set up #{profile_fan_id} for mode #{mode_candidate_friend} podium_id=#{podium_id}"
        case mode_candidate_friend
          when 1 then ActiveRecord::Base.connection().update("UPDATE profiles SET podium_id = #{podium_id}, podium_ids = '#{podium_id}' WHERE id='#{profile_fan_id}'")
          # when 2 then ActiveRecord::Base.connection().update("UPDATE profiles SET podium_ids = CONCAT(podium_ids,',','#{podium_id}') WHERE id='#{profile_fan_id}'")
        end
      }
      
    }
    puts "#{hash_podium.size} created"
  end
  
end