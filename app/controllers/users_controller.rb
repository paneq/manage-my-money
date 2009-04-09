class UsersController < ApplicationController

  before_filter :login_required, :only => [:edit, :destroy, :update]
  before_filter :check_perm, :only => [:edit, :destroy, :update]
  # render new.rhtml
  def new
    @user = User.new
  end

  
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Dzięki za rejestrację! Już Ci wysyłamy e-mail z adresem do aktywacji konta."
    else
      flash[:error]  = "Przepraszamy, ale nie udało nam się założyć konta dla Ciebie. Spróbuj ponownie lub skontaktuj się z nami."
      render :action => 'new'
    end
  end


  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Rejestracja zakończona ! Zaloguj się i działaj już teraz."
      redirect_to login_path
    when params[:activation_code].blank?
      flash[:error] = "Zabrakło kodu aktywacyjnego. Przejdź dokładnie pod adres, który wysłaliśmy w wiadomości e-mail."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "Nie udało nam się znaleźć użytkownika o podanym kodzie aktywacyjnym. Być może już aktywowałeś swoje konto- spróbuj się zalogować."
      redirect_back_or_default('/')
    end
  end


  def edit
    prepare_arrays_for_view
    session[:return_to] = request.env['HTTP_REFERER']
  end


  def update
    if params[:commit] == 'Anuluj'
      redirect_back
      return
    end

    if self.current_user.update_attributes(params[:user])
      flash[:notice] = 'Ustawienia zostały zaktualizowane.'
      redirect_back
    else
      prepare_arrays_for_view
      render :action => 'edit'
    end
  end

  def destroy
    user = User.authenticate(self.current_user.login, params[:password])
    unless user
      flash[:notice]  = "Hasło niepoprawne"
      prepare_arrays_for_view
      render :action => 'edit'
    else
      if self.current_user.destroy
        flash[:notice]  = "Twoje konto i wszystkie dane zostały usunięte"
        redirect_to logout_path
      else
        flash[:notice]  = "Nie udało się usunąć konta, skontaktuj się z administratorem"
        redirect_to('/')
      end
    end
  end


  private

  
  def check_perm
    user_id_from_request = params[:id]
    unless self.current_user.id == user_id_from_request.to_i
      flash[:error]  = "Thou shall not do this with this user"
      redirect_back_or_default('/')
      return false
    end
    return true
  end

  def prepare_arrays_for_view
    #    @transaction_amount_limit_types = User.TRANSACTION_AMOUNT_LIMIT_TYPES.keys
    @multi_currency_balance_calculating_algorithms = User.MULTI_CURRENCY_BALANCE_CALCULATING_ALGORITHMS.keys
    @currencies_for_select = @current_user.visible_currencies
  end

  def redirect_back
    unless session[:return_to].blank?
      ret_to = session[:return_to]
      session[:return_to] = nil
      redirect_to ret_to
    else
      redirect_to :controller => 'sessions', :action => 'default'
    end
  end



end
