class TransferItemsController < ApplicationController

  before_filter :find_user
  before_filter :check_perm, :only => [:edit]

  layout 'main'
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

#   def list
#     @transfer = Transfer.find(session[:transfer_id])
#     @transfer_item_pages, @transfer_items = paginate :transfer_items, :per_page => 10
#   end
# 
#   def show
#     @transfer = Transfer.find(session[:transfer_id])
#     @transfer_item = TransferItem.find(params[:id])
#   end
# 
#   def new
#     @user = User.find( session[ :user_id ] )
#     @transfer = Transfer.find(session[:transfer_id])
#     @transfer_item = TransferItem.new
#   end
# 
#   def create
#     if params[:transfer_item][:category].is_a? String
#       nr = params[:transfer_item][:category].to_i
#       params[:transfer_item][:category] = Category.find( nr )
#     end
# 
#     @transfer_item = TransferItem.new(params[:transfer_item])
#     @transfer_item.transfer = Transfer.find( session[:transfer_id] )
#     
#     if @transfer_item.save
#       flash[:notice] = 'TransferItem was successfully created.'
#       redirect_to :action => 'list'
#     else
#       render :action => 'new'
#     end
#   end

  def edit
  end

  def update
    if @transfer_item.update_attributes(params[:transfer_item])
      flash[:notice] = 'This item was successfully updated.'
      redirect_to :action => 'show', :id => @transfer_item
    else
      render :action => 'edit'
    end
  end
  
  
  ###########################
  # @author Robert Pankowecki
  # remote
  def edit_remote
    check_perm #why remote calls do not check perm automagicaly?
    where="transfer-item-#{@transfer_item.id}"
    render :update do |page|
      page.replace_html where , :partial => 'transfer_items/form_remote' , :locals => { :transfer_item => @transfer_item }
    end
  end
  
  
  ###########################
  # @author Robert Pankowecki
  # remote
  def discard
    check_perm
    where="transfer-item-#{@transfer_item.id}"
    render :update do |page|
      page.replace_html where , :partial => 'transfers/transfer_item_details_body' , :object => @transfer_item
    end
  end
  
  ###########################
  # @author Robert Pankowecki
  # remote
  def update_remote
    check_perm
    params[:transfer_item][:category] = Category.find(params[:transfer_item][:category].to_i) if params[:transfer_item][:category]
    params[:transfer_item][:currency] = Currency.find(params[:transfer_item][:currency].to_i) if params[:transfer_item][:currency]
    if @transfer_item.update_attributes(params[:transfer_item])
      flash[:notice] = 'This item was successfully updated.'
      where="transfer-item-#{@transfer_item.id}"
      where_flash = "flash-notice-#{@transfer_item.transfer.id}"
      render :update do |page|
        page.replace_html where_flash, 'This item was successfully updated.' 
        page.visual_effect :highlight, where_flash
        page.replace_html where , :partial => 'transfers/transfer_item_details_body' , :object => @transfer_item
      end
    else
      #TODO: Write an error managemnt
    end
  end
# 
#   def destroy
#     TransferItem.find(params[:id]).destroy
#     redirect_to :action => 'list'
#   end
  
  private
  
  def check_perm
    @transfer_item = TransferItem.find(params[:id])
    if @transfer_item.category.user.id != @user.id
      @transfer_item = nil
      flash[:notice] = 'You do not have permission to view this transfer item'
      redirect_to :action => :index, :controller => :categories
      return
    end
  end
end
