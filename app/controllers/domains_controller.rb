class DomainsController < ApplicationController
  
  # method post
  # edit the descriptor of a feature
  def edit
    raise "params=#{params.inspect}"
  end

  # a user update a product's feature
  # this is a rjs  
  def update_definition
    domain = Domain.find(params[:id])
		domain.update_definition(params[:options])
		@last_updated = Time.now
		render :update do |page|  
		  page.replace(domain_dom_id(domain.id),
              render(:partial => "/domains/edit", :locals => {:domain => domain}))
    end
    
  end

  # remove a tag from an enumerated domain
  # GET /domains/remove_tag/:tag_id
  def remove_tag
    tag_id = params[:tag_id]
    raise "error"
  end
  
  # add a new tag (as a label) to an enumerated domain
  # POST /domains/add_tag
  # this is a rjs (a post/form_remote_tag)
  def add_tag
    domain = Domain.find(params[:domain_id])
    domain.add_new_tag_with_label(params[:new_tag_label])
        
    respond_to do |format|
      format.js { render :update do |page|  
        page.replace(domain_dom_id(domain.id), 
                          render(:partial => "/domains/edit", :locals => {:domain => domain } ))
                    end }
    end
    
  end
  
  # remove a tag from an enumerated domain
  # GET /domains/remove_tag/:tag_id (rjs)
  def delete_tag
    domain = Domain.find(params[:domain_id])
    domain.destroy_tag(params[:tag_id])
    respond_to do |format|
      format.js { render :update do |page|  
          page.replace(domain_dom_id(domain.id), 
                            render(:partial => "/domains/edit", :locals => {:domain => domain } ))
                      end }
    end
  end

  # edit a subdomain
  # POST /domains/update_subdomain/:id (rjs)  
  def edit_selection    
    subdomain = Domain.find(params[:id])
    before = subdomain.descriptor.inspect
    selected_tag_ids = (params[:selected_tag_ids] || []).collect { |id| Integer(id) }
    subdomain.update_definition(:set_tags => selected_tag_ids)
    
    after = subdomain.descriptor.inspect
    @last_updated = Time.now
		
    render :update do |page|  
          page.replace(domain_dom_id(subdomain.id), 
                       render(:partial => "/domains/edit", :locals => {:domain => subdomain } ))
    end
  end
  
end

