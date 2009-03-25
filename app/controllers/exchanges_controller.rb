class ExchangesController < ApplicationController
  
  layout 'main'
  before_filter :login_required
  before_filter :set_exchange, :only => [:show, :edit, :update, :destroy]
  before_filter :set_currencies, :only => [:show, :new, :edit, :update]
  

  # Index of all pairs of possible currencies exchanges
  def index
    @currencies = Currency.for_user(self.current_user).find(:all, :order => 'user_id ASC, long_symbol ASC')
    @pairs = @currencies.combination(2)
    @exchange = flash[:exchange] || default_exchange
  end


  def list
    @currencies = Currency.for_user(self.current_user)
    @c1 = Currency.for_user(self.current_user).find_by_id(params[:left_currency])
    @c2 = Currency.for_user(self.current_user).find_by_id(params[:right_currency])
    @c1, @c2 = @c2, @c1 if @c2.id < @c1.id
    
    @exchanges = self.current_user.exchanges.daily.paginate :page => params[:page],
      :order => 'day DESC',
      :per_page => 20,
      :conditions => {
      :left_currency_id => @c1.id,
      :right_currency_id => @c2.id
    }
    @exchange = flash[:exchange] || Exchange.new(:left_currency => @c1, :right_currency => @c2)
  end


  def show
    render :action => :edit
  end


  def new
    @exchange = default_exchange
    render :action => :edit
  end


  def edit
  end

  
  def create
    change_currencies_to_objects
    @exchange = Exchange.new(params[:exchange])
    @exchange.day_required = true
    @exchange.user = self.current_user
    if @exchange.save
      flash[:notice] = 'Utworzono nowy kurs'
    else
      flash[:notice] = 'Utworzenie nowego kursu zakończyło się niepomyślnie.'
      flash[:exchange] = @exchange
    end
    redirect_to :back
  end


  def update
    change_currencies_to_objects
    @exchange.user = self.current_user
    if @exchange.update_attributes(params[:exchange])
      flash[:notice] = 'Zaktualizowano kurs.'
      redirect_to @exchange
    else
      flash[:notice] = 'Aktualizacja kursu zakończyła się niepomyślnie.'
      render :action => :edit
    end
  end


  def destroy
    @exchange.destroy
    redirect_to exchanges_list_path(:left_currency => @exchange.left_currency, :right_currency => @exchange.right_currency)
  end


  protected

  
  def set_exchange
    @exchange = self.current_user.exchanges.find_by_id(params[:id])
  end

  def set_currencies
    @currencies = Currency.for_user(self.current_user)
  end


  private

  
  def change_currencies_to_objects
    @c1 = params[:exchange][:left_currency] = Currency.for_user(self.current_user).find_by_id(params[:exchange][:left_currency])
    @c2 = params[:exchange][:right_currency] = Currency.for_user(self.current_user).find_by_id(params[:exchange][:right_currency])
  end

  def default_exchange
    default = self.current_user.default_currency
    rest = Currency.for_user(@current_user) - [default]
    Exchange.new(:left_currency => default, :right_currency => rest.first)
  end

end
