#FIXME: I'm still to fat, boy. Cure me!
class TransfersController < HistoryController

  include ActionView::Helpers::ActiveRecordHelper
  
  before_filter :login_required
  before_filter :find_currencies_for_user
  before_filter :find_newest_exchanges, :only => [:index, :edit, :create, :update, :destroy]
  before_filter :check_perm_for_transfer , :only => [:show_details, :hide_details, :show , :edit_with_items, :destroy]


  def index
    create_empty_transfer
    @transfers = self.current_user.newest_transfers.map{|t| {:transfer => t} }
  end


  def search
    @range = get_period_range('transfer_day')
    @transfers = self.
      current_user.
      transfers.
      find(:all, :order => 'day ASC, id ASC', :conditions => ['day >= ? AND day <= ?', @range.begin, @range.end] ).
      map { |t| {:transfer => t} }
      
    respond_to do |format|
      format.html {}
      format.js {render_transfer_table}
    end
  end


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
        page.replace_html 'show-transfer-quick', :partial=>'transfers/quick_transfer', :locals => { :current_category => @category }
      end
    else
      # TODO: change it so there will be a notice that something went wrong
      where = 'quick-transfers'
      render :update do |page|
        page.insert_html :bottom , where , :partial => '' , :object => @transfer
      end
    end
  end


  def show
  end

  
  def edit
    set_current_category
    @transfer = self.current_user.transfers.find_by_id(params[:id])
  end


  def update
    @transfer = self.current_user.transfers.find_by_id(params[:id])
    @transfer.attributes = params[:transfer]
    if @transfer.save
      respond_to do |format|
        format.html {}
        format.js do
          render_transfer_table do |page|
            if @category && @category.transfers.find_by_id(@transfer.id)
              #same code as show_details but i could not move it into method and i do not know why.
              page.hide "show-details-button-#{@transfer.id}"
              page.insert_html :bottom,
                "transfer-in-category-#{@transfer.id}",
                :partial => 'transfer_details',
                :object => @transfer,
                :locals => {:current_category_id => params[:current_category], :include_subcategories => params[:include_subcategories]}
            end
          end
        end
      end
    else
      show_transfer_errors()
    end
  end


  def create
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = self.current_user
    if @transfer.save
      respond_to do |format|
        format.html {}
        format.js do
          render_transfer_table do |page| #FIXME: It would be cool to write page.render_transfer_table. that way we could move it into js.rjs files...
            create_empty_transfer
            page.replace_html 'show-transfer-full', :partial=>'transfers/form', :locals => {:current_category => @category, :transfer => @transfer}
          end
        end
      end
    else
      show_transfer_errors()
    end
  end


  def destroy
    @transfer.destroy
    flash[:notice] = 'Transfer został usunięty'
    respond_to do |format|
      format.html
      # Railscast: 043_ajax_with_rjs REFACTOR
      format.js { render_transfer_table }
    end
  end

  
  protected
  
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


  private


  def show_transfer_errors
    respond_to do |format|
      format.html {}
      format.js do
        where = extract_form_errors_id
        render :update do |page|
          page.replace_html where, error_messages_for(:transfer, :message => nil)
        end
      end #format.js
    end
  end
  
end
