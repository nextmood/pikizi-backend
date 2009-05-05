class MappersController < ApplicationController
  
  # Home page
  def index
    @mappers = Mapper.find(:all)
  end
  
  
end
