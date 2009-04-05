class CategoriesController < HistoryController
 
  before_filter :login_required
  before_filter :find_currencies_for_user, :only => [:show, :new, :create]
  before_filter :find_newest_exchanges, :only => [:show]
  before_filter :check_perm, :only => [:show, :search, :destroy, :edit, :update]

  cache_sweeper :category_sweeper
  include RedirectHelper

  #FIXME @NOTE: this line should be somewhere else
  LENGTH = (1..31).to_a

  def show
    create_empty_transfer
    set_variables_for_rendering_transfer_table
  end


  def search
    @range = get_period_range('transfer_day')
    @include_subcategories = !!params[:include_subcategories]
    respond_to do |format|
      format.html {}
      format.js {render_transfer_table}
    end
  end

  
  def index
    #Optimization: 
    #preloading 'name_with_path' from cache
    @categories = self.current_user.categories.with_level
    @categories.each do |c|
      c.name_with_path
    end
    @saldos = Category.compute(:default, @current_user, @categories, false, Date.today)
    @subsaldos = Category.compute(:default, @current_user, @categories, true, Date.today)
  end


  def destroy
    catch(:indestructible) do
      @category.destroy
      flash[:notice] = "Usunięto kategorię"
    end
    flash[:notice] ||= "Nie można usunąć kategorii"
    redirect_back_or_root
  end


  def new
    @parent = @current_user.categories.find(params[:parent_category_id].to_i) if params[:parent_category_id]
    @category = Category.new()
    @categories = @current_user.categories
    @system_categories = SystemCategory.all
    @subcategories = empty_subcategories(@system_categories)
  end


  def create
    @parent = params[:category][:parent] = @current_user.categories.find( params[:category][:parent])
    params[:category][:new_subcategories] ||= []
    format_openinig_balance
    @category = Category.new(params[:category])
    @category.user = @current_user
    if @category.save_with_subcategories
      flash[:notice] ||= 'Utworzono nową kategorię'
      redirect_to categories_url
    else
      @system_categories = SystemCategory.all
      @subcategories = subcategories_from_params(@system_categories, params[:category][:new_subcategories])
      @categories = @current_user.categories
      flash[:notice] = 'Nie udało się utworzyć kategorii.'
      render :action => 'new'
    end
  end


  def edit
    @parent = @category.parent
    @top = self.current_user.categories.top.of_type(@category.category_type).find(:first)
    @system_categories = SystemCategory.find_all_by_category_type(@category)
    @subcategories = empty_subcategories(@system_categories)
    @current_subcategories = @category.descendants
  end

   
  def update
    params[:category][:new_subcategories] ||= []
    @parent = params[:category][:parent] = if !@category.is_top? and params[:category][:parent]
      @current_user.categories.find(params[:category][:parent])
    else
      nil
    end
    @category.update_attributes(params[:category])
    if @category.save_with_subcategories
      flash[:notice] = 'Zapisano zmiany.'
      redirect_to category_path(@category)
    else
      @parent = @category.parent
      @top = self.current_user.categories.top.of_type(@category.category_type).find(:first)
      @system_categories = SystemCategory.all
      @subcategories = subcategories_from_params(@system_categories, params[:category][:new_subcategories])
      @current_subcategories = @category.descendants
      flash[:notice] = 'Nie udało się zaktualizować kategorii.'
      render :action => 'edit'
    end
  end

 
  private

  def check_perm
    @category = self.current_user.categories.find(params[:id])
  rescue
    flash[:notice] = 'Brak uprawnień do oglądania tej kategorii.'
    redirect_to :action => :index , :controller => :categories
  end


  def format_openinig_balance
    if params[:category][:opening_balance]
      params[:category][:opening_balance].strip!
      params[:category][:opening_balance].slice!(" ")
    end
  end


  def empty_subcategories(system_categories)
    subcategories = SequencedHash.new;
    system_categories.each {|sc| subcategories[sc.id] = {:selected => false, :category => sc}}
    subcategories
  end

  
  def subcategories_from_params(system_categories, params_categories)
    subcategories = empty_subcategories(system_categories)
    params_categories.each do |new_sc|
      subcategories[new_sc.to_i][:selected] = true
    end
    subcategories
  end


end
