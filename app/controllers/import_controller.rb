class ImportController < CooperationController

  include FileRecognizer

  layout 'main'


  ACCEPTED_CONTENT_TYPES = %w(text/csv text/xml)
  INVALID_FILE_WARNING = 'Wysłano nieprawidłowy plik. Akceptowane są jedynie pliki XML dla Inteligo oraz CSV dla mBanku'

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
