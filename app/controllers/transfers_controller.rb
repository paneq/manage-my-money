class TransfersController < ApplicationController

  require 'hash'
  
  layout 'main'
  before_filter :login_required
  before_filter :check_perm_for_transfer , :only => [:show_details , :show , :edit_with_items, :destroy]


  # remote
  # TODO: sprawdzenie czy kategorie i waluty naleza do usera
  def quick_transfer
    data = params['data'].to_hash
    @transfer = Transfer.new(data.pass('description', 'day(1i)', 'day(2i)','day(3i)'))
    @transfer.user = self.current_user
    
    ti1 = TransferItem.new(data.pass('description','category_id', 'currency_id', 'value'))
    ti2 = TransferItem.new(data.pass('description', 'currency_id'))
    ti2.value = -1* ti1.value
    ti2.category = self.current_user.categories.find(data['from_category_id'])
    @transfer.transfer_items << ti2 << ti1
    
    if @transfer.save
      render_transfer_table do |page|
        page.replace_html 'form-for-transfer-quick', :partial=>'transfers/quick_transfer', :object => { :category_id => @category.id}
      end
    else
      # TODO: change it so there will be a notice that something went wrong
      where = 'quick-transfers'
      render :update do |page|
        page.insert_html :bottom , where , :partial => '' , :object => @transfer
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


  #TODO do wyrzucenie totalnie!
  def make
    if request.get? 
      session[:how_many] = {:outcome => 0, :income => 0}
      @choosen_category_id = params[:choosen_category_id].to_i
    else
      if (params[:id].nil?) # we do not check if this user can update this transfer! should be changed somehow
        @transfer = Transfer.new
        @transfer.transfer_items.build
      else
        @transfer = Transfer.find( params[:id])
      end
      @transfer.transfer_items.each {|ti| ti.destroy}
      d = params[:transfer]['day(3i)'].to_i
      m = params[:transfer]['day(2i)'].to_i
      y = params[:transfer]['day(1i)'].to_i
      @transfer.day = Date.new(y , m , d)
      @transfer.user = self.current_user
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
        if params[:embedded]=='true'#full transfer w kategorii
          render_transfer_table do |page|
            page.replace_html 'form-for-transfer-full', :partial=>'transfers/full_transfer', :locals => {:category_id => params[:current_category] ,:embedded=>true}
          end
      
        elsif session[:back_to_category] # z kategorii wywolalismy edit
          redirect_to :action => :show, :controller => :categories, :id => session[:back_to_category]
        
        else
          #po prostu transfer new
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



  #TODO
  def edit
    @transfer = self.current_user.transfers.find_by_id(params[:id])
  end
  
  #TODO
  def update
    params[:transfer][:transfer_items_attributes] ||= {}
    @transfer = self.current_user.transfers.find_by_id(params[:id])
  end

  #TODO: Prztestowac jeszcze tworzenie wszystkich transferow i usuwanie w zlozonym i prostym przypadku

  #TODO
  def create
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = self.current_user
    if @transfer.save
      respond_to do |format|
        format.html {}
        format.js do
          render_transfer_table do |page|
            page.replace_html 'form-for-transfer-full', :partial=>'transfers/full_transfer', :locals => {:category_id => params[:current_category] ,:embedded=>true}
          end
        end
      end
    else
      throw :a
    end
  end


  ###################
  # TODO: WYRZUCIC I NIECH UZYWA EDIT I PARTIAL FULL_TRANSFER DO ODRYSOWANIA ORAZ transfer.update_paramaters zamiast mega make
  # s 68 w ksiazce
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


  #TODO
  def destroy
    # TODO: if else ??
    @transfer.destroy
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
  


  private
  
  def check_perm_for_transfer
    @transfer = Transfer.find(params[:id])
    if @transfer.user.id != self.current_user.id
      flash[:notice] = 'You do not have permission to view this transfer!'
      @transfer = nil
      redirect_to :action => :index, :controller => :categories
      return
      #why doesn't it work ? There is no flash ?
    end
  end
  
end
