class CategoriesController < ApplicationController
 
  layout 'main'
  before_filter :login_required
  before_filter :check_perm, :only => [:show , :remove, :search]

  # @NOTE: this line should be somewhere else
  LENGTH = (1..31).to_a


  # remote
  #should not be here!
  #should be by js hidden and showed
  def quick
    where = "form-for-quick-transfer"
    render :update do |page|
      page.insert_html :bottom , where , :partial => 'quick_transfer' , :object => { :category_id => params[:category_id] }
    end
  end


  def show
    session[:category_id] = @category.id
    session[:how_many] = {:outcome => 0, :income => 0}
    @start_day = 1.month.ago.to_date
    @end_day = Date.today
    if params['show_with_subcategories']
      #@transfers_to_show, @value_between = @category.transfers_with_subcategories_saldo_between(@start_day.to_date , @end_day.to_date)
      #@value = @category.value_with_subcategories
      raise "test if ever happen"
    else
      @transfers_to_show = @category.transfers_with_saldo_for_period_new(@start_day.to_date , @end_day.to_date)
      @value_between = @category.saldo_for_period_new(@start_day.to_date, @end_day.to_date)
      @value = @category.saldo_at_end_of_day(@end_day.to_date)
    end
  end

  #TODO: sprawic zeby search dzialał jak show
  # i wszystko co z tym zwiazanie jak np metody w modelu dla podkategorii
  # aktualnie leci exception z braku metody
  def search
    session[:category_id] = @category.id
    @start_day, @end_day = get_period('transfer_day')
    if params['show_with_subcategories']
      @transfers_to_show, @value_between = @category.transfers_with_subcategories_saldo_between(@start_day.to_date , @end_day.to_date)
      @value = @category.value_with_subcategories
    else
      @transfers_to_show, @value_between = @category.transfers_with_saldo_between(@start_day.to_date , @end_day.to_date)
      @value = @category.value
    end
    render :action => :show
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
    @parent = params[:parent_category_id].to_i
    @category = Category.new()
    @categories = self.current_user.categories
    @currencies = self.current_user.visible_currencies
  end


  def create
    params[:category][:parent] = self.current_user.categories.find( params[:category][:parent].to_i )
    @category = Category.new(params[:category])
    @category.user = self.current_user
    if @category.save
      if params[:category][:opening_balance].to_i != 0
        make_opening_transfer
      end
      flash[:notice] ||= 'Utworzono nową kategorię'
      redirect_to categories_url
    else
      flash[:notice] = 'Category was NOT successfully created.'
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
   
   
   
  def make_opening_transfer
    #new opening_balance transfer here
    #category = Category.find(params['data']['category'])
    currency = self.current_user.visible_currencies.find(params[:category][:opening_balance_currency].to_i)
    value = params[:category][:opening_balance]
    value.slice!(" ") #removes all spaces from input data so string like "10 000" will be converted to "10000" and treted well by "to_i" method in next line
    value = value.to_i
    transfer = Transfer.new
    transfer.day = Date.today
    transfer.user = self.current_user
    transfer.description = "Bilans otwarcia"
    
    t1 = TransferItem.new
    t1.description = "Bilans otwarcia"
    t1.value = value
    t1.category = @category
    t1.currency = currency

    t2 = TransferItem.new
    t2.description = t1.description
    t2.value = -1 * t1.value
    t2.currency = t1.currency
    opening_category = self.current_user.categories.top_of_type(:BALANCE)
      
    t2.category = opening_category
    
    transfer.transfer_items << t2 << t1
    if transfer.save
      flash[:notice] = 'Utworzono kategorię wraz z bilansem otwarcia'
    end
  end


  def check_perm
    @category = self.current_user.categories.find(params[:id])
    unless @category
      flash[:notice] = 'You do not have permission to view this category'
      @category = nil
      redirect_to :action => :show_categories , :controller => :category
      #why doesn't it work ? There is no flash ?
    end
  end
  
  
  
  ########################
  # @author: Robert Pankowecki
  def get_date_from_params
  
    if params[:transfer].nil? or params[:transfer]['start(1i)'].nil?
      @start_time = Time.now.years_ago(2).to_date
    else
      #       @start_time = params[:start].to_time
      d = params[:transfer]['start(3i)'].to_i
      m = params[:transfer]['start(2i)'].to_i
      y = params[:transfer]['start(1i)'].to_i
      @start_time = Date.new(y , m , d)
    end
    if params[:transfer].nil? or params[:transfer]['end(1i)'].nil?
      @end_time = Time.now.years_since(2).to_date
    else
      d = params[:transfer]['end(3i)'].to_i
      m = params[:transfer]['end(2i)'].to_i
      y = params[:transfer]['end(1i)'].to_i
      @end_time = Date.new(y , m , d)
    end
  end
    
end
