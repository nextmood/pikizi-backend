# - The domain (a list of acceptable values) associated with a Feature
# This is an abstract class, see DomainNumeric, DomainEnumerated, DomainBinary, DomainTag
#todo handle multiple values with a cardinality property
class Domain < ActiveRecord::Base
  
  serialize :descriptor, Hash
  
  belongs_to :feature
  
  MULTI_VALUES_SEPARATOR = ";"
  
  # convert a raw value into a value compatible/interpreted by the domain
  # returns the genuine value (i.e. the clean up of the raw value) to store in a FeatureValue later on
  # raise an "ArgumenError" is the value is not compatible with the domain
  # if nil returns nil
  # if [] returns []
  # if raw_value returns the genuine(raw_value)
  # if [raw_value1, raw_value2, ...] returns [genuine(raw_value1), genuine(raw_value2), ...]
  # if string using a ';' -> split
  def check_value(value) 
    if value and value != ""
      # the raw value exists
      value = value.split(MULTI_VALUES_SEPARATOR) if value.is_a?(String) and value.include?(MULTI_VALUES_SEPARATOR)
      if cardinality == 1
      	raise "............error cardinality=#{cardinality} value=#{value}" if value.is_a?(Array)
      	self.check_value_bis(value)
      else
        value = [value, value] if cardinality == 2 and !value.is_a?(Array)
        raise "............error cardinality=#{cardinality} value=#{value}" unless value.is_a?(Array)
      	value.collect { |v| self.check_value_bis(v) }
      end
    else
      # the raw value is nil or an empty string
      cardinality == 1 ? nil : []
    end
  end
    
  # does a value belongs to the domain
  def include?(value) 
    if value and value != ""
      value = value.split(MULTI_VALUES_SEPARATOR) if value.is_a?(String) and value.include?(MULTI_VALUES_SEPARATOR)
      if value.is_a?(Array)
        value.all? { |v| include_bis(v) }
      else
        include_bis(value)
      end
    else
      true
    end
  end
    
  # convert a genuine value to a string for display
  def as_string(x) "#{x}" end    
       
  # convert a domain to an html string for display
  def definition_as_html() "default html #{self.class}" end
  
  # create a new Domain object (of domain_type) with default values...
  # cardinality
  # - 1 (the default), 0-1 value for the feature (return a singleton)
  # - 2 (or n), the numnbers of values are between 0 and n (return an array)
  # - nil, cardinality is between 0 and infinite (return an array)
  def self.create_default(feature, domain_type, cardinality=1)
    data = Domain.datas.detect { |hash| hash[:domain_type] == domain_type }
    raise "no data for domain_type=#{domain_type}" unless data
    new_domain = data[:class_name].create(:descriptor => {}, :feature => feature, :cardinality => cardinality)
    new_domain.update_definition(new_domain.default_definition)
    new_domain
  end
      
  # return a default definition for a newly created domain
  def default_definition() {} end

  # updating the domain definition
  def update_definition(definition) update_attribute(:descriptor, definition) end
    
  # list of domain_type and classes
  def self.datas 
    @@datas ||= [ {:domain_type => "text", :class_name => DomainText },
                  {:domain_type => "binary", :class_name => DomainBinary },
                  {:domain_type => "numeric", :class_name => DomainNumeric },
                  {:domain_type => "tag", :class_name => DomainTag },
                  {:domain_type => "date", :class_name => DomainDate }]
  end
  
  
end

# Describe a text domain
class DomainText < Domain

  def check_value_bis(value) value.to_s end

  def include_bis(value) true end
  
  def definition_as_html() "(free text)" end
  
  
end


# Describe a possible numeric value
# - between min and max
# - a relation order is associated
# - fied unit
class DomainNumeric < Domain


  def default_definition() {:min => 0.0, :max => 1000.0, :format => "% .2f$"} end

  def definition_as_html() "from #{as_string(descriptor[:min])} ... to #{as_string(descriptor[:max])}" end
  
  def check_value_bis(raw_value)
    if value = DomainNumeric.is_a_float(raw_value) and include?(value)
      value
    else
      raise "oups not in domain numeric #{raw_value}"
    end
  end

  def include_bis(value) 
    min_value = DomainNumeric.is_a_float(descriptor[:min])
    max_value = DomainNumeric.is_a_float(descriptor[:max])
    (value.nil? or ( (min_value.nil? or value >= min_value) and (max_value.nil? or value <= max_value) ))
  end

  def self.is_a_float(x)
    begin
      Float(x)
    rescue
      nil
    end
  end
  
  
  def as_string(x) 
    begin
      x ? descriptor[:format] % x : 'N/A' 
    rescue
      "#{x}"
    end
  end
      
  
end

# Describe a date domain
class DomainDate < Domain

  def default_definition() {:min => DomainDate.is_a_time("2000/1/1"), :max => DomainDate.is_a_time("2020/1/1") } end

  def definition_as_html() "from #{as_string(descriptor[:min])} ... to #{as_string(descriptor[:max])}" end

  def check_value_bis(raw_value)
    if value = DomainDate.is_a_time(raw_value) and include?(value)
      value
    else
      raise ArgumentError, "#{value.inspect} is not in min=#{descriptor[:min].inspect}/max=#{descriptor[:max].inspect}", caller
    end
  end

  def include_bis(value) (value.nil? or ( (descriptor[:min].nil? or value >= descriptor[:min]) and (descriptor[:max].nil? or value <= descriptor[:max]) )) end
  
  def self.is_a_time(x)
    begin
      if x.is_a?(Time)
        x
      elsif x.is_a?(String)
        Time.parse(x)
      elsif x.is_a?(Hash)
        Time.parse("#{x[:year]}/#{x[:month]}/#{x[:day]}") 
      end
    rescue
      nil
    end
  end
  
  def as_string(x) 
    begin
      x ? x.strftime('%Y %B %d') : "N/A" 
    rescue
      "#{x}"
    end
  end
   
end

# Describe an enumerated list of values (tags) (this is an abstract class)
class DomainEnumerated < Domain

  # list of tags ids for this domain
  # serialize :tag_ids, Array
  def tag_ids() (descriptor[:tag_ids] ||= []) end
  
  # when a DomainEnumerated is destroyed, delete all associated tags 
  def destroy
    tag_ids.clone.each { |tag_id| destroy_tag(tag_id) }
    super
  end
  
  # destroy a tag association between a domain and a tag
  # doesnt update the descriptor of the domain !
  def destroy_tag(tag_id)
    tag_id = DomainEnumerated.is_an_integer(tag_id)
    raise "Unknown tag tag_id=#{tag_id}" unless tag_id and tag_ids.include?(tag_id)
    descriptor[:tag_ids].delete(tag_id)
    update_attribute(:descriptor, descriptor)
    begin
      dtag = Dtag.find(tag_id)
    rescue
      
    else
      dtag.destroy
    end

  end
  
  # add a tag (or a set of tags) to this domain
  # return the new Dtag object created
  def add_new_tag_with_label(tag_label)
  	raise "error" unless tag_label.is_a?(String)
    tag = Dtag.create(:label => DomainEnumerated.standardize_tag(tag_label), :domain_id => id)
    tag_ids << tag.id
    update_attribute(:descriptor, descriptor)
    tag
  end

  # return a hash of tag_id, tag associated with this domain
  def get_hash_tags(reload = false) 
    @hash_tags = nil if reload
    @hash_tags ||= Dtag.find(:all, :conditions => ["id IN (?)", tag_ids]).inject({}) { |hash, tag| hash[tag.id] = tag; hash }
  end

  # return a list of tags
  def get_tags() tag_ids.inject([]) { |l, tag_id| l << get_tag_from_id(tag_id)  } end

  # return a list pf pair for select
  def get_tags_for_select() tag_ids.inject([]) { |l, tag_id| l << [get_tag_from_id(tag_id).label, tag_id]  } end
    
  # return a tag object from it's id
  def get_tag_from_id(tag_id, reload = false) get_hash_tags(reload)[tag_id] end

  # return a tag object from it's label
  def get_tag_from_label(tag_label, reload = false)
    tag_label = DomainEnumerated.standardize_tag(tag_label)
    tag_id, tag = get_hash_tags(reload).detect { |id, tag| tag.label == tag_label }
    tag
  end
      
  # convert a tag id to a label
  def as_string(tag_id)
    if tag_id
      if tag_id.is_a?(Array) 
        tag_id.collect { |ti| the_tag = get_tag_from_id(ti); the_tag ? the_tag.label : "???" }
      else
        get_tag_from_id(tag_id).label
      end
    else
      "N/A"
    end
  end
      
  # only one option (set_tags)
  def update_definition(definition)  
    raise "error no id for domain #{id}, #{self.inspect}" unless id
    raise "wrong set_tags definition" unless definition[:set_tags].nil? or definition[:set_tags].is_a?(Array)

    # :set_tags is an array either of tag's ids (so already existing) or a list of string (in this case the tag 
    # will be created)
    new_tags_ids = definition[:set_tags].collect { |tag_or_id| check_value_bis(tag_or_id) }.flatten
    
    # compute the difference between the existings tag of this domain and the new list
    tag_ids_to_destroy = tag_ids.clone

    tags_ids_to_add = []
    
    new_tags_ids.each { |tag_id| tag_ids_to_destroy.delete(tag_id) if tag_ids_to_destroy.include?(tag_id) }
    
    tag_ids_to_destroy.each { |tag_id_to_destroy| destroy_tag(tag_id_to_destroy) }
 
    super({:tag_ids => new_tags_ids})
  end
  
  def definition_as_html
    tag_ids.collect { |tag_id| 
            tag = get_tag_from_id(tag_id)
            tag ? tag.label : "<span style=\"color:red;\">#{tag_id}</span>"
             }.join(", ")
  end 
  
  
  # domain is open per default
  # tag_to_check is either a string or an id
  # return the tag id
  def check_value_bis(string_or_id) 
    if string_or_id.is_a?(Dtag)
      string_or_id.id
    elsif tag_as_id = DomainEnumerated.is_an_integer(string_or_id)
      raise ArgumentError, "#{tag_as_id.inspect} is not a Dtag id (tag_ids=#{tag_ids.inspect})", caller unless tag_ids.include?(tag_as_id)
      tag_as_id
    elsif string_or_id.is_a?(String)
      unless tag = get_tag_from_label(string_or_id)
        # comment next  line if u want to have a close domain
        tag = add_new_tag_with_label(string_or_id)
        #get_tag_from_label(string_or_id, true) # reload !!
      end
      raise ArgumentError, "#{string_or_id.inspect} has no tag matching", caller unless tag
        tag.id
    else
      raise ArgumentError, "wrong class check_value_bis #{string_or_id.inspect}", caller
    end
  end

  def include_bis(value) (value.nil? or descriptor[:tag_ids].include?(value)) end
    
  def self.standardize_tag(tag) tag.strip.downcase end

  def self.is_an_integer(x)
    begin
      Integer(x)
    rescue
      nil
    end
  end
  
end

# a domain made of yes/no value
class DomainBinary < DomainEnumerated

  def self.yes() "yes" end
  def self.no() "no" end
      
  def default_definition() {:set_tags => [DomainBinary.yes, DomainBinary.no]} end    

    
  def definition_as_html() "#{DomainBinary.yes}/#{DomainBinary.no}" end
  
      
end



# a domain made of a list of tags with only value possible
class DomainTag < DomainEnumerated

  def default_definition() {:set_tags => ["choice 1", "choice 2", "choice 3"]} end

  
end

