class UsersController < ApplicationController
  #ssl_required :login
  #ssl_allowed :index

  layout 'main'
  before_filter :find_user, :except => [:activate, :login, :index, :new, :create, :about, :about_one]

  # List of developers that has their own site in "About Us" section
  # I know this is not a proper place for such thing
  INDIVIDUAL = ['rupert' , 'sejtenik' , 'matti' ]
  
  def destroy
    session[:user_id] = nil
    session[:user_name] = ""
    flash[:notice] = 'You have removed your account'
    @user.destroy
    redirect_to :action => :index, :controller => :users
  end

  
  def login
    session[:user_id] = nil
    if request.post?
      user = User.authenticate(params[:name], params[:password])
      if user
        session[:user_id] = user.id
        session[:user_name] = user.name
        redirect_to :action => :index, :controller => :categories
      else
        flash[:notice] = "Invalid user/password combination or inactive account"
      end
    end
  end


  # This method search for user becuase logged use can view home site
  # but even if user is not logged we do not redirect him as in :find_user filter!
  def index
    @user = User.find(session[:user_id]) if session[:user_id]
  end
  
  
  def about
    @user = User.find(session[:user_id]) if session[:user_id]
  end

  
  def logout
    @user = User.find(params[:id])
    return unless @user.id == session[:user_id]
    session[:user_id] = nil
    session[:user_name] = ""
    flash[:notice] = 'You have been logged out'
    redirect_to '/'
  end

  
  def activate
    @user = User.find(params[:id])
    hash = params[:activate_hash]
    user_hash = @user.to_hash
    if hash == user_hash
      @user.active = true
      @user.save!
      flash[:notice] = "Your account is now active. You can log in."
      redirect_to :action => :index
    else
      flash[:notice] = "Account has NOT been activated"
      redirect_to :action => :index
    end
  end


  def new
    @user = User.new
  end


  def create
    @user = User.new(params[:user])    
    if @user.save
      flash[:notice] = 'User was successfully created.'      
      RegisterMailer.deliver_sent(@user)
      redirect_to :action => 'index'
    else
      flash[:notice] = 'User was NOT successfully created.'
      render :action => 'new'
    end

  end


  # @description: Regarding to send param "who" decide which partial
  #               should be used to show additional information about some of us
  # remote
  def about_one
    where_hide = "3p-member"
    where_show = "about-one"
    @who = params[:who]
    render :update do |page|
      page.remove(where_hide)
      if INDIVIDUAL.member?(@who)  
        page.insert_html :bottom, where_show, :partial => "/3p/#{@who}", :object => @who
      else
        page.insert_html :bottom, where_show, :partial => "/3p/others", :object => @who 
      end
    end
  end  

end
