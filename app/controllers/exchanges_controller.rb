class ExchangesController < ApplicationController
  
  layout 'main'
  before_filter :login_required
  before_filter :find_and_set_exchange, :only => [:show, :edit, :update, :destroy]
  before_filter :check_perm_read, :only => [:show]
  before_filter :check_perm_write, :only => [:edit, :update, :destroy]
  

  # Index of all pairs of possible currencies exchanges
  def index
    @currencies = Currency.for_user(self.current_user).find(:all, :order => 'user_id ASC, long_symbol ASC')
    @pairs = @currencies.combination(2)
  end


  def list
    @currencies = Currency.for_user(self.current_user)
    @c1 = Currency.for_user(self.current_user).find_by_id(params[:left_currency])
    @c2 = Currency.for_user(self.current_user).find_by_id(params[:right_currency])
    @c1, @c2 = @c2, @c1 if @c2.id < @c1.id
    
    @exchanges = Exchange.paginate :page => params[:page],
      :order => 'day DESC',
      :per_page => 20,
      :conditions => {
      :currency_a => @c1.id,
      :currency_b => @c2.id,
      :user_id => self.current_user.id
    }
    @exchange = flash[:exchange] || Exchange.new(:left_currency => @c1, :right_currency => @c2)
    flash[:exchange]
  end


  def show
    @exchange = self.current_user.exchanges.find_by_id(params[:id])
  end


  def new
    @exchange = Exchange.new
    render :action => :new_or_edit
  end


  def create
    @c1 = params[:exchange][:left_currency] = Currency.for_user(self.current_user).find_by_id(params[:exchange][:left_currency])
    @c2 = params[:exchange][:right_currency] = Currency.for_user(self.current_user).find_by_id(params[:exchange][:right_currency])
    @exchange = Exchange.new(params[:exchange])
    @exchange.user = self.current_user
    if @exchange.save
      flash[:notice] = 'Utworzono nowy kurs'
    else
      flash[:notice] = 'Utworzenie nowego kursu zakończyło się niepomyślnie.'
      flash[:exchange] = @exchange
    end
    redirect_to :back
  end


  def edit
    render :action => :new_or_edit
  end

  def update
    if @exchange.update_attributes(params[:exchange])
      flash[:notice] = 'Exchange was successfully updated.'
      redirect_to @exchange
    else
      flash[:notice] = 'Exchange was successfully updated.'
      render :action => :edit
    end
  end


  def destroy
    @exchange.destroy
    redirect_to exchanges_path
  end
  
  private
  
  def find_and_set_exchange
    @exchange = Exchange.find(params[:id])
  end
  
  def check_perm_read
    if @exchange.user != nil and @exchange.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to view this exchange'
      @exchange= nil
      redirect_to exchanges_path
    end
  end
    
  def check_perm_write
    if @exchange.user == nil or @exchange.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to modify this exchange'
      @exchange = nil
      redirect_to exchanges_path
    end
  end
end
