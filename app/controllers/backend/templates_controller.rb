class Backend::TemplatesController < Backend::BackendController

  before_filter :pre_load

  def index
    @templates = current_inventory_pool.templates.search params[:query], { :star => true, :page => params[:page], :per_page => $per_page }

    respond_to do |format|
      format.html
      format.js { search_result_rjs(@templates) }
    end

  end

  def show
  end

  def new
    @my_template = Template.new
    render :action => 'show'
  end

  def create
    @my_template = Template.new
    @my_template.inventory_pools << current_inventory_pool
    update
  end
  
  def update
    @my_template.update_attributes(params[:template])
    redirect_to :action => 'show', :id => @my_template
  end

  def destroy
    if params[:model_link_id]
      @my_template.model_links.delete(@my_template.model_links.find(params[:model_link_id])) # OPTIMIZE
      redirect_to :action => 'models'
    else
      @my_template.destroy
      redirect_to :action => 'show'
    end
  end
  
#################################################################

  def models
    
  end
  
  def add_model(model_link = params[:model_link])
    @model = current_inventory_pool.models.find(model_link[:model_id])
    @my_template.model_links.create(:model => @model, :quantity => model_link[:quantity])
    redirect_to :action => 'models'
  end
  
#################################################################

  private
  
  def pre_load
    params[:template_id] ||= params[:id] if params[:id]
    # NOTE @template is a reserved variable
    @my_template = current_inventory_pool.templates.find(params[:template_id]) if params[:template_id]
    
    @tabs = []
    @tabs << :template_backend if @my_template
  end

end
