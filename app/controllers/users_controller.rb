class UsersController < ApplicationController

  layout 'main'
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
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end


  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to login_path
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end


  def edit
    prepare_arrays_for_view
  end


  def update
    if self.current_user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :controller => 'sessions', :action => 'default'
    else
      prepare_arrays_for_view
      render :action => 'edit'
    end
  end

  
  def destroy
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
    @transaction_amount_limit_types = User.TRANSACTION_AMOUNT_LIMIT_TYPES.keys
    @multi_currency_balance_calculating_algorithms = User.MULTI_CURRENCY_BALANCE_CALCULATING_ALGORITHMS.keys
  end


end
