class AutocompleteController < ApplicationController
  before_filter :login_required

  def complete
    atr = params[:transfer][:new_transfer_items_attributes]
    text = atr[atr.keys.first][:description]
    text << ' '

    #    "adasd         asdasd asdasd asd asd ".gsub(/ +/, '* ')
    #=> "adasd* asdasd* asdasd* asd* asd* "
    text.gsub!(/ +/, '* ')
    
    @transfer_items = TransferItem.search text+'*', :include => [:category, :currency], :conditions => {:user_id => self.current_user.id}
    render :layout => false
  end



end
