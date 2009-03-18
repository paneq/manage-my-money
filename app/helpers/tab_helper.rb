module TabHelper
  include ShadowHelper

  # Makes tab to show and hide elements <br />
  #
  # def tab([[:quick, 'Szybki'],[:full, 'Pelny'],[:search,'Wyszukaj']], :transfer, 'Pelny' <br />
  # Options : <br />
  # * name - Required option
  # * selected ex. => :quick
  # <br />
  def tab(all, name, selected = nil)    
    selected = all.first.first if selected.nil? || !all.map{|element, name| element}.include?(selected)

    menu_name = 'kind-of' + "-" + name.to_s
    show_name = 'show' + "-" + name.to_s
    
    render :partial => 'shared/tab', :locals => {:all => all, :menu_name => menu_name, :selected => selected, :show_name => show_name}
  end

  
  def tab_container(name, options={}, &block)
    defaults = {:id => "show-#{name.to_s}", :class => "tab-page"}
    defaults.merge!(options)
    concat content_tag(:div, capture(&block), defaults)
  end
end