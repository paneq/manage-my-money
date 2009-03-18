module TabHelper
  include ShadowHelper

  # Makes tab to show and hide elements <br />
  #
  # def tab([[:quick, 'Szybki'],[:full, 'Pelny'],[:search,'Wyszukaj']], :name => :transfer <br />
  # Options : <br />
  # * name - Required option
  # * menu_prefix
  # * menu_sufix
  # * show_prefix
  # * selected ex. => :quick
  # <br />
  def tab(all, options = {})
    defaults = {:name => :nil, :menu_prefix => 'kind-of', :menu_sufix => 'tab', :show_prefix => 'show', :selected => :nil}
    defaults.merge!(options)

    throw ":name cannot be blank" if defaults[:name].blank?
    throw ":menu_prefix and :show_prefix cannot be the same" if defaults[:menu_prefix].to_s == defaults[:show_prefix].to_s
    
    selected = all.first.first
    selected = defaults[:selected] if !defaults[:selected].nil? && all.map{|element, name| element}.include?(defaults[:selected])

    menu_name = defaults[:menu_prefix].nil? ? defaults[:name].to_s : (defaults[:menu_prefix].to_s + "-" + defaults[:name].to_s)

    show_name = defaults[:show_prefix].nil? ? defaults[:name].to_s : (defaults[:show_prefix].to_s + "-" + defaults[:name].to_s)
    
    render :partial => 'shared/tab', :locals => {:all => all, :menu_name => menu_name, :selected => selected, :show_name => show_name}
  end

end