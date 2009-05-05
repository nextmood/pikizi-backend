
# Mixin for a cached (in memory) Hierarchy based on BetterNestedSet
# the object should define a method label (reading)
# a method path (reading and writing)
#
module Hierarchy
  
  def self.included(base)
    base.acts_as_nested_set
    base.extend(ClassMethods)
  end
  
  def Hierarchy.path_separator() "/" end 
  
  # set_up node_children and node_parent attributes for all_nodes
  # in other words, link objects together
  # return all roots objects in this context
  def Hierarchy.load_tree(all_nodes)
    l_roots = []
    hash_id_node = {}
    all_nodes.each { |node| hash_id_node[node.id]=node; node.node_children=[]; node.node_parent=nil }
    all_nodes.each { |node| 
      if node.root? or hash_id_node[node.parent_id].nil?
        l_roots << node
      else
        node.node_parent=hash_id_node[node.parent_id]
        node.node_parent.node_children << node 
      end
    }
    l_roots
  end
  
    
  # This module provides a cache Mechanism for BetterNestedSet
  module ClassMethods  
    
    # return an object from it's path
    # sql extra is a list of products
    def get_node_from_path(path, should_exist=true, sql_extra = {})
      node = self.find_by_path(path, sql_extra) # active , record
      raise "path not found ! path=#{path.inspect}" if should_exist and node.nil?
      node
    end
    
    # return all node of this Hierarchy
    # with accessors node_children and node_parent prefilled
    # options => sql options
    def node_roots(options={}) 
      Hierarchy.load_tree(self.find(:all, options))
    end 

    # add a node in the db, manage the path
    def add_node(node, parent=nil)  
      if parent 
        node.move_to_child_of(parent) # add link in database
        node.update_attribute(:path, "#{parent.path}#{Hierarchy.path_separator}#{node.label}")
      else
        node.update_attribute(:path, "#{node.label}")
      end
      
      node
    end
    
    
  end
  
  # ===================================================================================  
  # Instance methods
  # ===================================================================================  
  
  attr_accessor :node_parent, :node_children

  # after changing the label, or the index of the current node (saved in DB)
  # propagate the modification in the path and all descendants path
  # and reorder the children based on comparable
  def update_path_and_sort(path_root = nil)
    unless path_root
      load_tree
      path_root = root? ? "" : "#{parent.path}#{Hierarchy.path_separator}"
    end
    new_path = "#{path_root}#{label}"
    update_attribute(:path, new_path)
    node_children.each { |child| child.update_path_and_sort("#{new_path}#{Hierarchy.path_separator}") } 
    self
  end
  
  def remove_node
    self.children.each(&:remove_node)
    self.on_node_destroy # call back to destroy attached objects
    self.destroy
  end
  
  # return the node, with all it's children linked (through node_parent and node_children methods)
  # only one database request
  def load_tree
    tree_root = Hierarchy.load_tree(self_and_descendants)
    raise "error loading tree for #{label}... result=#{tree_root.inspect}" unless tree_root.size == 1 and id == tree_root.first.id
    self.node_children = tree_root.first.node_children
    self
  end
  
  # check if the node is right under root
  def is_first_level?() parent and parent.root? end

  # return all objects attached to a node or any of its descendants
  # objects are collected from a node using a dynamic method
  def descendants_linked_objects(method_objects_collector, limit=nil, objects = nil)
    unless objects
      load_tree
      objects = Set.new
    end
    
    objects.merge(self.send(method_objects_collector))
    node_children.each { |child| child.descendants_linked_objects(method_objects_collector, limit, objects) }
    objects.to_a
  end
    
  # sort order for comparable
  def <=>(n1, n2) (n1.index == n2.index) ? (n1.label <=> n2.label) : (n1.index <=> n2.index) end
    
end
  
    

