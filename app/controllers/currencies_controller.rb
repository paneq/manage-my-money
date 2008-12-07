class CurrenciesController < ApplicationController
  
  layout 'main'
  before_filter :login_required
  before_filter :find_and_set_currency, :except =>[:index, :new, :create, :create_remote]
  before_filter :check_perm_read, :only => [:show]
  before_filter :check_perm_write, :only => [:edit, :update, :destroy]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #   verify :method => :post, :only => [ :destroy, :create, :update ],
  #          :redirect_to => { :action => :list }

  def index
    @currencies = self.current_user.visible_currencies
  end

  def show
    @currency = Currency.find(params[:id])
  end


  def new
    @currency = Currency.new
  end


  # remote
  def create_remote
    @currency = Currency.new(params[:currency])
    @currency.user = self.current_user
    where_insert = 'currencies-list'
    where_replace = 'new-currency'
    where_error = 'flash_notice'
    if @currency.save
      render :update do |page|
      page.remove where_replace
      page.insert_html :bottom, where_insert, :partial => 'currencies/currency', :object => @currency
      page.visual_effect :highlight, "currency-#{@currency.id}"
      @currency = nil
      page.insert_html :bottom, where_insert, :partial => 'currencies/new_currency'
      page.replace_html where_error, :partial => 'currencies/empty'
      end
    else
      render :update do |page|
        page.visual_effect :highlight, where_error
        page.replace_html where_error, :partial => 'currencies/error', :object => "Adding currency failed: #{ @currency.errors.full_messages.join(', ') } "
      end
    end
  end


  def create
    @currency = Currency.new(params[:currency])
    @currency.user = self.current_user
    if @currency.save
      flash[:notice] = 'Currency was successfully created.'
      redirect_to :action => :index
    else
      render :action => 'new'
    end
  end


  def edit
  end


  def update
    if @currency.update_attributes(params[:currency])
      flash[:notice] = 'Currency was successfully updated.'
      redirect_to :action => 'show', :id => @currency
    else
      render :action => 'edit'
    end
  end


  def destroy
    @currency.destroy
    redirect_to currencies_url
  end
  
  private
  
    def find_and_set_currency
      @currency = Currency.find(params[:id])
    end
  

    def check_perm_read
      if @currency.user != nil and @currency.user.id != self.current_user.id
        flash[:notice] = 'You do not have permission to view this currency'
        @currency = nil
        redirect_to :action => :index , :controller => :currencies
      end
    end
    

    def check_perm_write
      if @currency.user == nil or @currency.user.id != self.current_user.id
        flash[:notice] = 'You do not have permission to modify this currency'
        @currency = nil
        redirect_to :action => :index , :controller => :currencies
      end
    end
end
