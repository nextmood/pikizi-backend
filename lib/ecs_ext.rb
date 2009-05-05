require 'amazon/ecs'

class Ecs
  
  def self.browsenode_lookup(browsenode_id, opts={})
    opts = self.options.merge(opts) if self.options
    opts[:operation] = 'BrowseNodeLookup'
    opts[:BrowseNodeId] = browsenode_id
    self.send_request(opts)
  end
  
end