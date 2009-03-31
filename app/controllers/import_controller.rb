class ImportController < HistoryController
    
  include FileRecognizer
  before_filter :login_required
  before_filter :find_currencies_for_user, :only => [:parse_bank]
  before_filter :find_newest_exchanges, :only => [:parse_bank]


  ACCEPTED_CONTENT_TYPES = %w(text/csv text/xml)
  INVALID_FILE_WARNING = 'Wysłano nieprawidłowy plik. Akceptowane są jedynie pliki XML dla Inteligo oraz CSV dla mBanku'
  INVALID_GNUCASH_FILE_WARNING = 'Nieprawidłowy plik Gnucash lub brak pliku'


  def import
    @category = self.current_user.categories.find_by_id(params[:category_id]) if params[:category_id]
    @categories = self.current_user.categories
    @category ||= @categories.first
  end


  def parse_bank
    @category = self.current_user.categories.find(params[:category_id].to_i)

    if (params[:file].blank?) || (!ACCEPTED_CONTENT_TYPES.include? params[:file].content_type.chomp)
      render_invalid_file_info
      return
    end

    content = params[:file].read
    file_name = params[:file].original_filename

    recognized = recognize_file(content, file_name)
    unless recognized
      render_invalid_file_info
      return
    end

    begin
      @result = (recognized.to_s + '_parser').camelcase.constantize.parse(content, self.current_user, @category) # :inteligo => @result = InteligoParser.parse
    rescue Exception => e
      raise e if ENV['RAILS_ENV'] == 'development'
      render_invalid_file_info
      return
    end


    render 'parse'
    #CSV Mbanku => WIN-1250

  end

  def parse_gnucash

    if (params[:file].blank?) || (params[:file].content_type.chomp != 'text/xml')
      render_invalid_file_info INVALID_GNUCASH_FILE_WARNING
      return
    end

    content = params[:file].read
    file_name = params[:file].original_filename

    if !file_name.ends_with? 'xml'
      render_invalid_file_info INVALID_GNUCASH_FILE_WARNING + ': ' + file_name
      return
    end

    @result = GnucashParser.parse(content, self.current_user)

    render 'import_status'
  end




  def create
    @transfer = Transfer.new(params[:transfer])
    @transfer.user = self.current_user
    error_id = params[:error_id]
    if @transfer.save
      render :update do |page|
        # FIXME: TODO: DOES NOT WORK CORRECTLY AND REQUIRES AUTOMATED TESTING, Broken after transfer view refactoring. Possible day when fixed: 29 march 2009
        page.replace_html "transfer-edit-#{error_id}", :text => 'Transfer został pomyślnie zapisany'
        # TODO, dodać jakieś mignięcie albo coś
      end
    else
      render :update do |page|
        # FIXME: TODO: DOES NOT WORK CORRECTLY AND REQUIRES AUTOMATED TESTING
        page.replace_html "transfer-errors-#{error_id}", error_messages_for(:transfer, :message => nil)
      end 
    end

  end


  private


  def render_invalid_file_info(info = INVALID_FILE_WARNING)
    flash[:notice] = info
    @categories = self.current_user.categories
    @category ||= @categories.first
    render :action => :import
  end

end
