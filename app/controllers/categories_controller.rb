class CategoriesController < ApplicationController
 
  layout 'main'
  before_filter :login_required
  before_filter :check_perm, :only => [:show , :remove, :search]

  # @NOTE: this line should be somewhere else
  LENGTH = (1..31).to_a
  #
  #
  #  # remote
  #  #should not be here!
  #  #should be by js hidden and showed
  #  def quick
  #    where = "form-for-quick-transfer"
  #    render :update do |page|
  #      page.insert_html :bottom , where , :partial => 'quick_transfer' , :object => { :category_id => params[:category_id] }
  #    end
  #  end


  def show
    create_empty_transfer
    set_variables_for_rendering_transfer_table
  end


  def search
    @category = self.current_user.categories.find(params[:id])
    
  end

  
  def index
  
  end


  def destroy
    @category = self.current_user.categories.find(params[:id])
    @destroyed = false
    catch(:indestructible) do
      @category.destroy
      @destroyed = true
    end
    respond_to do |format|
      format.html do
        flash[:notice] = @destroyed ? "Usunięto kategorię" : "Nie można usunąć kategorii"
        redirect_to categories_path
      end
      format.js # destroy.js.rjs
    end

  end


  def new
    @parent = @current_user.categories.find(params[:parent_category_id].to_i) if params[:parent_category_id]
    @category = Category.new()
    @categories = @current_user.categories
    @currencies = @current_user.visible_currencies
  end


  def create
    @parent = params[:category][:parent] = @current_user.categories.find( params[:category][:parent].to_i )
    format_openinig_balance
    @category = Category.new(params[:category].merge(:user => @current_user))
    if @category.save
      flash[:notice] ||= 'Utworzono nową kategorię'
      redirect_to categories_url
    else
      @categories = @current_user.categories
      @currencies = @current_user.visible_currencies
      flash[:notice] = 'Nie udało się utworzyć kategorii.'
      render :action => 'new'
    end
  end


  def edit
    @category = self.current_user.categories.find(params[:id])
    @parent = @category.parent
    @top = self.current_user.categories.top_of_type(@category.category_type)
  end

  
  def update
    #begin
    @category = self.current_user.categories.find(params[:id])
    @category.name = params[:category][:name]
    @category.description = params[:category][:description]
    @category.parent = self.current_user.categories.find(params[:category][:parent].to_i) if !@category.is_top? and params[:category][:parent]
    @category.save!
    flash[:notice] = 'Category was successfully updated.'
    redirect_to categories_url
    #rescue Exception
    # thr
    #render :action => 'edit'
    #end
  end

 
  private

  def check_perm
    @category = self.current_user.categories.find(params[:id])
    unless @category
      flash[:notice] = 'You do not have permission to view this category'
      @category = nil
      redirect_to :action => :show_categories , :controller => :category
      #why doesn't it work ? There is no flash ?
    end
  end

  def format_openinig_balance
    if params[:category][:opening_balance]
      params[:category][:opening_balance].strip!
      params[:category][:opening_balance].slice!(" ")
    end
  end
end
