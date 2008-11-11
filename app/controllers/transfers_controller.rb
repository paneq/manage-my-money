class TransfersController < ApplicationController

  layout 'main'
  before_filter :find_user
  before_filter :check_perm_for_transfer , :only => [:show_details , :show , :edit_with_items, :destroy]


  public

#   def save_in_session
#     session[:transfer_id] = params[:id]
#     redirect_to :action => :index
#   end


  
  #remote
  def full_transfer_show
  
    @choosen_category_id  = session[:category_id]
    render :update do |page|
        page.replace_html 'form-for-transfer', :partial => 'transfers/full_transfer', :locals => { :category_id => params[:category_id] , :embedded => true}
        page.replace_html 'kind-of-transfer', :partial => 'transfers/kind_of_transfer', :locals => {:active_tab => :full , :category_id => params[:category_id]}
    end
  end
  
  #remote
  def quick_transfer_show
    render :update do |page|
        page.replace_html 'form-for-transfer', :partial => 'transfers/quick_transfer', :object => { :category_id => params[:category_id] }
        page.replace_html 'kind-of-transfer', :partial => 'transfers/kind_of_transfer', :locals => {:active_tab => :quick, :category_id => params[:category_id]}
    end
  
  end
  
  #remote
  def search_show
    render :update do |page|
        page.replace_html 'form-for-transfer', :partial => 'transfers/search_transfers', :locals => { :category_id => params[:category_id] }
        page.replace_html 'kind-of-transfer', :partial => 'transfers/kind_of_transfer', :locals => {:active_tab => :search, :category_id => params[:category_id]}
    end
  
  end


  #################
  # @author: Robert Pankowecki
  # remote
  # TODO: check if ti1. ti2.category.user == @user ?
  def quick_transfer
    category = Category.find(params['data']['category'])
    currency = Currency.find(params['data']['currency'])
    transfer = Transfer.new
    transfer.day = Date.today
    transfer.user = @user
    transfer.description = (params['data']['description'])
    
    ti1 = TransferItem.new
    ti1.description = (params['data']['description'])
    ti1.value = (params['data']['value']).to_i
    ti1.category = category
    ti1.currency = currency
    
    ti2 = TransferItem.new
    ti2.description = (params['data']['description'])
    ti2.value = -1* (params['data']['value']).to_i
    @category = Category.find(params[:from_category_id])
    ti2.category = @category
    ti2.currency = currency
    transfer.transfer_items << ti2 << ti1
    if transfer.save
      @start_day = 1.month.ago.to_date
      @end_day = Date.today
    
      @transfers_to_show, @value_between = @category.transfers_with_saldo_between(@start_day.to_date , @end_day.to_date)
      @value = @category.value
      where = 'transfer-table-div'
      render :update do |page|
        page.replace_html where, :partial => 'categories/transfer_table'
        page.replace_html 'form-for-transfer', :partial=>'transfers/quick_transfer', :object => { :category_id => @category.id}
      end
      
      
      #where = 'quick-transfers'
      #render :update do |page|
      #  page.insert_html :bottom , where , :partial => 'category/transfer_for_subcategories' , :object => transfer
      #end
    else
      # TODO: change it so there will be a notice that something went wrong
      where = 'quick-transfers'
      render :update do |page|
        page.insert_html :bottom , where , :partial => '' , :object => transfer
      end
    end
  end


  #remote
  def show_details
    where_show = "transfer-in-category-#{params[:id]}"
    where_hide = "show-details-#{params[:id]}" 
    render :update do |page|
      page.remove where_hide
      page.insert_html :bottom, where_show, :partial => 'transfer_details', :object => @transfer
    end
  end
  
  #remote
  def hide_details
    where_show = "put-show-details-here-#{params[:id_to_hide]}"
    where_hide = "transfer_details_id_#{params[:id_to_hide]}"
    render :update do |page|
      page.remove where_hide
      page.insert_html :bottom, where_show, :partial => 'show_details' , :object => params[:id_to_hide]
    end
  end

  #remote
  def add_transfer_item
    session[:how_many][params[:type].intern] += 1
    number = session[:how_many][params[:type].intern]
    where = params[:type] + '_items'
    render :update do |page|
      page.insert_html :bottom, where, :partial=>'transfer_item', :object => { :type => params[:type], :number => number }
    end
  end

  #remote
  def remove_transfer_item
    render :update do |page|
      page.remove params[:id_to_remove]
    end
  end

  ################
  # @author: Robert Pankowecki
  # @author: Jaroslaw Plebanski
  # @author: Mateusz Pawlik
  def make
    if request.get? 
      session[:how_many] = {:outcome => 0, :income => 0}
      @choosen_category_id = params[:choosen_category_id].to_i
    else
      if (params[:id].nil?) # we do not check if this user can update this transfer! should be changed somehow
        @transfer = Transfer.new
      else
        @transfer = Transfer.find( params[:id])
      end
      @transfer.transfer_items.each {|ti| ti.destroy}
      d = params[:transfer]['day(3i)'].to_i
      m = params[:transfer]['day(2i)'].to_i
      y = params[:transfer]['day(1i)'].to_i
      @transfer.day = Date.new(y , m , d)
      @transfer.user = User.find(session[:user_id])
      @transfer.description = params[:transfer][:description]
      @transfer_items_from = []
      @transfer_items_to = []
      p = params[:outcome]
      (0..session[:how_many][:outcome]+1).each do |i|
#         unless p['category-' + i.to_s].nil? and p['description-' + i.to_s].nil? and p['value-' + i.to_s].nil?
        unless p['category-' + i.to_s].nil? or p['description-' + i.to_s].nil? or p['value-' + i.to_s].nil? or p['description-' + i.to_s].empty? or p['value-' + i.to_s].empty?
          transfer_item = TransferItem.new
          transfer_item.description = p['description-' + i.to_s]
          transfer_item.value = p['value-' + i.to_s].to_i * -1
          category = Category.find( p['category-' + i.to_s].to_i )
          transfer_item.category = category
          transfer_item.currency = Currency.find(p['currency-' + i.to_s].to_i)
          @transfer.transfer_items << transfer_item
          @transfer_items_from << transfer_item
        end
      end
      p = params[:income]
      (0..session[:how_many][:income]+1).each do |i|
#         unless p['category-' + i.to_s].nil? and p['description-' + i.to_s].nil? and p['value-' + i.to_s].nil?
        unless p['category-' + i.to_s].nil? or p['description-' + i.to_s].nil? or p['value-' + i.to_s].nil? or p['description-' + i.to_s].empty? or p['value-' + i.to_s].empty?
          transfer_item = TransferItem.new
          transfer_item.description = p['description-' + i.to_s]
          transfer_item.value = p['value-' + i.to_s].to_i
          category = Category.find(p['category-' + i.to_s].to_i)
          transfer_item.category = category
          transfer_item.currency = Currency.find(p['currency-' + i.to_s].to_i)
          @transfer.transfer_items << transfer_item
          @transfer_items_to << transfer_item
        end
        
      end



      t_description = @transfer.description
      if @transfer.save
      
        if params[:embedded]=='true'
          @category = Category.find(session[:category_id])
          @start_day = 1.month.ago.to_date
          @end_day = Date.today
  #     
          @transfers_to_show, @value_between = @category.transfers_with_saldo_between(@start_day.to_date , @end_day.to_date)
          @value = @category.value
          where = 'transfer-table-div'
          render :update do |page|
            page.replace_html where, :partial => 'categories/transfer_table'
            page.replace_html 'form-for-transfer', :partial=>'transfers/full_transfer', :locals => {:embedded=>true}
          end
      
        elsif session[:back_to_category]
          redirect_to :action => :show, :controller => :categories, :id => session[:back_to_category]
        
        else 
      
          @transfer = nil # dzieki temu przy odrysowywaniu nie nadpiusuje nam desciption poprzednim
          render :update do |page|
            page.replace_html 'form-for-transfer', :partial => 'full_transfer'
            page.replace_html 'form_errors' , :partial => 'sucess_transfer', :object => t_description
          end
        
        end  
        
      else #transfer.save
        @transfer = nil
        render :update do |page|
          page.replace_html 'form_errors' , :partial => 'failed_transfer', :object => t_description
        end
      end  # end of else (@transfer.save)
    end  # end of else (request xhr!)
  end # end of method make


  ############################
  # @author: Robert Pankowecki
  # half-remote
  # currently not in use
  # currently i do not know how to make it working
  def add_form_error (error)
    render :update do |page|
      page.remove 'error_in_form'
      page.insert_html :bottom, 'form_erros', :partial=>'error_in_form', :object => error
    end 
  end




  def edit
  
  end
  
  
  
  
  ###################
  # @author: Robert Pankowecki
  def edit_with_items
    session[:how_many] = {}
    @collection = {}
    @transfer.both_transfer_items do |type , table_of_items|
      nr = 0
      @collection[ type ] = []
      session[:how_many][ type ] = table_of_items.size
      table_of_items.each do |item|
        @collection[ type ] << { :type => type.to_s , :number => nr.to_s , :choosen => item.category.id , :description => item.description , :value => item.value}
        nr += 1
      end
    end
    session[:back_to_category] = session[:category_id]
  end





  ####################
  # @author: Generated by Rails
  # @author: Robert Pankowecki  
  # @note: Transfer items that belongs to destroyed transfer should be destroyed not
  #        not by the controller but by the MODEL. In fact they should be deleted by the
  #        DATABASE because of existing extern_key! Cascade deleting should be somehow enabled!
  def destroy
    id = @transfer.destroy_with_transfer_items.id
    respond_to do |format|
      format.html do 
        flash[:notice] = 'Transfer was sucesfully destroyed'
        redirect_to :action => 'show', :controller => 'categories', :id => session[:category_id]
      end
      format.js do
        render :update do |page|
          page.remove "transfer-in-category-line-#{id}"
          page.remove "transfer_details_id_#{id}"
        end
      end
    end
  end




  ####################
  # @author: Generated by Rails
  # @author: Robert Pankowecki
 # def list
    #@transfer_pages, @transfers = paginate :transfers, :per_page => 20
#    @transfers = @user.transfers
 #   @transfers.sort! { | t1, t2 | t1.day <=> t2.day }
 #   @transfers.reverse!
 # end
  


  private
  
  def check_perm_for_transfer
    @transfer = Transfer.find(params[:id])
    if @transfer.user.id != @user.id
      flash[:notice] = 'You do not have permission to view this transfer!'
      @transfer = nil
      redirect_to :action => :index, :controller => :categories
      return
      #why doesn't it work ? There is no flash ?
    end
  end
  
end
