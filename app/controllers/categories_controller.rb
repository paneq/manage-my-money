class CategoriesController < ApplicationController
 
  layout 'main'
  before_filter :login_required
  before_filter :check_perm, :only => [:show_with_subcategories , :show , :remove, :search]

  # @NOTE: this line should be somewhere else
  LENGTH = (1..31).to_a


  # remote
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

  def search
    session[:category_id] = @category.id
    if params['period'] == 'SELECTED'
      @start_day = Date.new(params['period_start']['year'].to_i, params['period_start']['month'].to_i, params['period_start']['day'].to_i)
      @end_day = Date.new(params['period_end']['year'].to_i, params['period_end']['month'].to_i, params['period_end']['day'].to_i)
    else
      @start_day = calculate_start_day(params['period'])
      @end_day   = calculate_end_day(params['period'])
    end
    if params['show_with_subcategories']
      @transfers_to_show, @value_between = @category.transfers_with_subcategories_saldo_between(@start_day.to_date , @end_day.to_date)
      @value = @category.value_with_subcategories
    else
      @transfers_to_show, @value_between = @category.transfers_with_saldo_between(@start_day.to_date , @end_day.to_date)
      @value = @category.value
    end
    render :action => :show
  end

  def period_changed_start
    @day = calculate_start_day(params['time'])
    render :layout => false
  end

  def period_changed_end
    @day = calculate_end_day(params['time'])
    render :layout => false
  end


  def index
  
  end
  
  # TODO move it to model!
  def remove
    unless @category.nil? or @category.parent_category.nil?
      @category.child_categories.each do |c| 
        c.parent_category = @category.parent_category
        c.save
      end
      @category.transfers.each do |t|
        t.transfer_items.each do |ti|
          if ti.category.id == @category.id 
            ti.category = Category.find(@category.parent_category.id) 
            ti.save
          end
        end
      end
      @category.destroy
      
      render :update do |page|
        page.replace_html 'category-tree', :partial => 'category', :collection => @user.top_categories 
      end
    else
      render :update do |page|
        page.replace_html 'flash_notice', 'You cannot remove this category.' 
        page.visual_effect :highlight, 'flash_notice'
      end
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
    @parent_categories = @category.user.categories.map {|cat| [cat.name, cat.id]}
    @parent_category_id = @category.parent_category.id if !@category.is_top?

  end




  def update
    @category = self.current_user.categories.find(params[:id])
    if params[:category][:parent_category]!=nil
      parent_category = Category.find(params[:category][:parent_category].to_i)
      params[:category][:parent_category] = parent_category
    end
    
    if @category.update_attributes(params[:category])
      flash[:notice] = 'Category was successfully updated.'
      redirect_to :action => 'show', :id => @category
    else
      render :action => 'edit'
    end
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
      return
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
