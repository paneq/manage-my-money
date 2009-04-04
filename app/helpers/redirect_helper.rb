# To change this template, choose Tools | Templates
# and open the template in the editor.

module RedirectHelper
  def redirect_back_or_root
    request.env["HTTP_REFERER"].blank? ? redirect_to(:action => :index, :controller => :categories) : redirect_to(:back)
  end

  def redirect_back_or(addr)
    request.env["HTTP_REFERER"].blank? ? redirect_to(addr) : redirect_to(:back)
  end
end
