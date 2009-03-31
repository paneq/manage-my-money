class AutocompleteController < ApplicationController
  before_filter :login_required


  def complete_transfer_item
    atr = params[:transfer][:transfer_items_attributes]
    @text = atr[atr.keys.first][:description]
    text = @text.clone
    text << ' '


    # to jest przyklad ktory dobrze tlumaczy
    # co robi moj kod
    # i jak dziala dzieki temu dobrze wyszukiwanie w sphinxie
    # jak wpisujesz opis transfer itemu
    # ze gwiazdkuje za kazdym skonczonym slowem
    # Przykład:
    #    "adasd         asdasd asdasd asd asd ".gsub(/ +/, '* ')
    #=> "adasd* asdasd* asdasd* asd* asd* "
    text.gsub!(/ +/, '* ')
    
    @transfer_items = TransferItem.search text,
      :conditions => {:user_id => self.current_user.id},
      :order => 'day DESC',
      :limit => 5,
      :include => [:category, :currency]
    @transfer_items.compact!

    @categories = Category.autocomplete(text, self.current_user)
    @categories.compact!
    
    render :layout => false
  rescue
    render :nothing => :true
  end


  def complete_transfer
    text = params[:transfer][:description]
    text << ' '
    text.gsub!(/ +/, '* ')
    @transfers = Transfer.search text,
      :conditions => {:user_id => self.current_user.id},
      :order => 'day DESC',
      :limit => 5
    @transfers.compact!
    render :layout => false
  rescue
    render :nothing => :true
  end

end
