class ImportController < CooperationController

  layout 'main'


  ACCEPTED_CONTENT_TYPES = %w(text/csv text/xml)
  INVALID_FILE_WARNING = 'Wysłano nieprawidłowy plik. Akceptowane są jedynie pliki XML dla Inteligo oraz CSV dla mBanku'
  INVALID_FILE_INFO = 'Wystąpił błąd w czasie przetwarzania pliku.'


  def import
    @category = self.current_user.categories.find_by_id(params[:category_id]) if params[:category_id]
    @categories = self.current_user.categories
    @category ||= @categories.first
  end


  def parse
    @category = self.current_user.categories.find(params[:category_id].to_i)
    unless ACCEPTED_CONTENT_TYPES.include? params[:file].content_type.chomp
      render_invalid_file_info
      return
    end

    render :text => params[:file].read
    #TODO parsowanie i pokazywanie strony gdzie rzeczy do wyboru
    #CSV Mbanku => 1250
  end

  
  private


  def render_invalid_file_info
    flash[:notice] = INVALID_FILE_WARNING
    @categories = self.current_user.categories
    @category ||= @categories.first
    render :action => :import
  end

end
