class CurrenciesController < ApplicationController
  
  before_filter :login_required
  before_filter :check_perm_edit, :only => [:edit, :update, :destroy]

  def index
    @currencies = Currency.for_user(@current_user).find(:all, :order => 'name')
  end

  
  def show
    @currency = Currency.for_user(@current_user).find(params[:id])
  rescue
    flash[:notice] = 'Brak uprawnień do oglądania jednostki.'
    redirect_to currencies_path
  end


  def new
    @currency = Currency.new
  end


  def create
    @currency = Currency.new(params[:currency])
    @currency.user = @current_user
    if @currency.save
      flash[:notice] = 'Utworzono nową jednostkę.'
      redirect_to :action => :index
    else
      render :action => 'new'
    end
  end


  def edit
  end


  def update
    if @currency.update_attributes(params[:currency])
      flash[:notice] = 'Zmiany zostały zapisane.'
      redirect_to :action => 'show', :id => @currency
    else
      render :action => 'edit'
      flash[:notice] = 'Zmiany nie zostały zapisane.'
    end
  end


  def destroy
    flash[:notice] = unless @currency.destroy
      if @currency.why_not_destroyed == :has_transfer_items
        'Nie można usunąć jednostki, gdyż istnieją w systemie transakcje korzystające z niej'
      else
        'Nie udało się usunąć jednostki'
      end
    else
      'Usunięto jednostkę.'
    end
    redirect_to currencies_url
  end

  private

  def check_perm_edit
    @currency = @current_user.currencies.find(params[:id])
  rescue
    flash[:notice] = 'Brak uprawnień do edycji jednostki.'
    redirect_to currencies_path
  end
  
end