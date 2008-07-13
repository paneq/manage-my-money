# class TransferItemController < ApplicationController
# 
# layout 'main'
#   def index
#     list
#     render :action => 'list'
#   end
# 
#   # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#   verify :method => :post, :only => [ :destroy, :create, :update ],
#          :redirect_to => { :action => :list }
# 
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
# 
#   def edit
#     @transfer_item = TransferItem.find(params[:id])
#   end
# 
#   def update
#     @transfer_item = TransferItem.find(params[:id])
#     if @transfer_item.update_attributes(params[:transfer_item])
#       flash[:notice] = 'TransferItem was successfully updated.'
#       redirect_to :action => 'show', :id => @transfer_item
#     else
#       render :action => 'edit'
#     end
#   end
# 
#   def destroy
#     TransferItem.find(params[:id]).destroy
#     redirect_to :action => 'list'
#   end
# end
