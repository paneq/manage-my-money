class CategoriesController < HistoryController
 
  before_filter :login_required
  before_filter :find_currencies_for_user, :only => [:show]
  before_filter :find_newest_exchanges, :only => [:show]
  before_filter :check_perm, :only => [:show , :remove, :search]

  cache_sweeper :category_sweeper

  #FIXME @NOTE: this line should be somewhere else
  LENGTH = (1..31).to_a

  def show
    create_empty_transfer
    set_variables_for_rendering_transfer_table
  end


  def search
    @category = self.current_user.categories.find(params[:id])
    @range = get_period('transfer_day', true)
    @include_subcategories = !!params[:include_subcategories]
    respond_to do |format|
      format.html {}
      format.js {render_transfer_table}
    end
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
    @system_categories = SystemCategory.all
    @subcategories = empty_subcategories(@system_categories)
  end


  def create
    @parent = params[:category][:parent] = @current_user.categories.find( params[:category][:parent].to_i )
    params[:new_subcategories] ||= []
    format_openinig_balance
    @category = Category.new(params[:category].merge(:user => @current_user))
    @category.new_subcategories = params[:new_subcategories]
    if @category.save_with_subcategories
      flash[:notice] ||= 'Utworzono nową kategorię'
      redirect_to categories_url
    else
      @system_categories = SystemCategory.all
      @subcategories = subcategories_from_params(@system_categories, params[:new_subcategories])
      @categories = @current_user.categories
      @currencies = @current_user.visible_currencies
      flash[:notice] = 'Nie udało się utworzyć kategorii.'
      render :action => 'new'
    end
  end


  def edit
    @category = self.current_user.categories.find(params[:id])
    @parent = @category.parent
    @top = self.current_user.categories.top.of_type(@category.category_type).find(:first)
    @system_categories = SystemCategory.find_all_by_category_type(@category)
    @subcategories = empty_subcategories(@system_categories)
    @current_subcategories = @category.descendants
  end

   
  def update
    @category = self.current_user.categories.find(params[:id])
    attr = params[:category]
    @category.update_attributes attr.pass(:name, :description, :email, :bankinfo, :system_category_id)
    @category[:type] = attr[:type] if attr[:type] && [Category, LoanCategory].map{|klass| klass.to_s}.include?(attr[:type])
    @category.parent = self.current_user.categories.find(attr[:parent].to_i) if !@category.is_top? and attr[:parent]
    params[:new_subcategories] ||= []
    @category.new_subcategories = params[:new_subcategories]
    if @category.save_with_subcategories
      flash[:notice] = 'Zapisano zmiany.'
      redirect_to category_url(@category)
    else
      @parent = @category.parent
      @top = self.current_user.categories.top.of_type(@category.category_type).find(:first)
      @system_categories = SystemCategory.all
      @subcategories = subcategories_from_params(@system_categories, params[:new_subcategories])
      @current_subcategories = @category.descendants
      flash[:notice] = 'Nie udało się zaktualizować kategorii.'
      render :action => 'edit'
    end
  end

 
  private

  def check_perm
    @category = self.current_user.categories.find(params[:id])
    unless @category
      flash[:notice] = 'You do not have permission to view this category'
      @category = nil
      redirect_to :action => :show_categories , :controller => :category
      #FIXME why doesn't it work ? There is no flash ?
    end
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
