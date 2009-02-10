# Methods added to this helper will be available to all templates in the application.

require File.expand_path(File.dirname(__FILE__) + '../../../lib/date_extensions')
require 'erb'

module ApplicationHelper
  include Forms::ApplicationHelper

  PERIODS = [[:SELECTED, 'Wybrane z menu']] + Date::PERIODS

  #Returns all periods including :Selected which cannote be computed by Date.compute
  def get_periods
    return PERIODS
  end

  # Returns id='name-#{obj.id}'
  def obj_id(name, obj)
    "id='#{name}-#{obj.id}'"
  end

  # Returns hash { :id => 'name-#{obj.id}' }
  def obj_hash_id(name, obj)
    {:id => "#{name}-#{obj.id}"}
  end

  # display_if(proc_object)
  # display_if { 1 == 2 }
  #
  # Returns "display:none" if condition is evaluated as false
  # otherwise returns empty string.
  def display_if(condition = nil, &block)
    raise 'Condition as Proc or code block required' if condition.nil? && !Kernel.block_given?
    condition = block if condition.nil?
    return '' if condition.call == true
    return 'display:none'
  end


  # display_if(proc_object)
  # display_if { 1 == 2 }
  #
  # Returns style="display:none" if condition is evaluated as false
  # otherwise returns style="" string.
  def style_display_if(condition = nil, &block)
    raise 'Condition as Proc or code block required' if condition.nil? && !Kernel.block_given?
    condition = block if condition.nil?
    return "style=\"#{display_if(condition)}\""
  end


  def add_transfer_item(transfer_item_type)
    jsfunction_code = link_to_function 'Nowy element' do |page|
      page.insert_html :bottom, "full-#{transfer_item_type.to_s.downcase}-items", :partial => '/transfers/transfer_item', :locals => {:hack => true}, :object => TransferItem.new(:transfer_item_type => transfer_item_type, :currency_id => @current_user.default_currency.id)
    end
    jsfunction_code.gsub! "onclick=\"try", "onclick=\"var my_uid = uid();\n try "; #TODO: wyjąc metodę UID  z head'a layoutu
    jsfunction_code.gsub! "PUT_ID_HERE", "&quot; + my_uid +&quot;"
    return jsfunction_code
  end



  # TODO: Using  result += may be a bed solution. At least it is not ellegant
  # Is there another, better way to do it? Like using erb Templates ?
  def date_period_fields(name, start_day = Date.today, end_day = Date.today)

    name_id = name.gsub(/_/, '-')
    select_name = name+'_period'
    start_field_name = get_date_start_field_name(name)
    end_field_name = get_date_end_field_name(name)
    computed_name = "#{name_id}-computed"

    result = ''
    result += <<-HTML
      <p id="#{name_id}-period"><label for="#{name_id}">Wybierz okres:</label>
    HTML

    result += select_tag select_name, options_from_collection_for_select(get_periods, :first, :second)

    result += get_date_field_start(name, start_day)
    result += get_date_field_end(name, end_day)
    result += <<-HTML
      </p>
    HTML

    result += <<-HTML
      <p id="#{computed_name}" style="display:none"></p>
    HTML

    function = <<-JS
      if (value == 'SELECTED') {
        Element.hide('#{computed_name}');
        Element.update('#{computed_name}','');
        Element.show('#{start_field_name}');
        Element.show('#{end_field_name}');
        return;
      }
      var text1 = '<p><label>Data początkowa: </label> '
      var text2 = '</p> <p><label>Data końcowa: </label> '
      var text3 = '</p>'
      switch (value) {
    JS


    Date::PERIODS.each do |period_type, period_name|
      range = Date.calculate(period_type)
      function << "case '#{period_type.to_s}': \n"
      function << "  text1 = text1 + '#{range.begin}' ;\n"
      function << "  text2 = text2 + '#{range.end}' ;\n"
      function << "break;\n"
    end
    function += <<-JS
    }
    text1 = text1 + text2 + text3
    Element.update('#{computed_name}', text1);
    Element.hide('#{start_field_name}');
    Element.hide('#{end_field_name}');
    Element.show('#{computed_name}');
    JS

    result += observe_field select_name,
      :on => 'click' ,
      :function => function
  end

  def get_date_field_start(name, start_day = Date.today)
    begin_field_name = get_date_start_field_name(name)
    result = <<-HTML
      <p id="#{begin_field_name}"><label for="#{begin_field_name}">Data początkowa: </label>
    HTML

    result += select_date start_day, :prefix => "#{name}_start"

    result += <<-HTML
      </p>
    HTML
  end


  def get_date_field_end(name, end_day = Date.today)
    end_field_name = get_date_end_field_name(name)
    result = <<-HTML
      <p id="#{end_field_name}"><label for="#{end_field_name}">Data końcowa: </label>
    HTML

    result += select_date end_day, :prefix => "#{name}_end"

    result += <<-HTML
      </p>
    HTML
  end


  def switch(div_id, name)
    result = ''
    result += link_to_function name, :id => "switch_for_#{div_id}", :onclick =>  <<-JS
      if(Element.visible('#{div_id}')) {
            Element.hide('#{div_id}')
        } else {
            Element.show('#{div_id}')
        }
    JS
  end


  # Makes tab to show and hide elements <br />
  #
  # def tab([[:quick, 'Szybki'],[:full, 'Pelny'],[:search,'Wyszukaj']], :name => :transfer <br />
  # Options : <br />
  # * name - Required option
  # * menu_prefix
  # * menu_sufix
  # * show_prefix
  # * active ex. => :quick
  # <br />
  # Refactor, make it faster... ?
  def tab(table, options = {})
    defaults = {:name => :nil, :menu_prefix => 'kind-of', :menu_sufix => 'tab', :show_prefix => 'form-for', :active => :nil}
    defaults.merge!(options)
    throw ":menu_prefix and :show_prefix cannot be the same" if defaults[:menu_prefix].to_s == defaults[:show_prefix].to_s
    throw ":name cannot be blank" if defaults[:name].blank?
    all = table
    show = nil
    show = defaults[:active] if !defaults[:active].nil? && table.map{|element, name| element}.include?(defaults[:active])
    show = table.first.first if show.nil?

    menu_name = defaults[:menu_prefix].nil? ? defaults[:name].to_s : (defaults[:menu_prefix].to_s + "-" + defaults[:name].to_s)

    active_class = menu_name + '-active'
    active_class += ('-' + defaults[:menu_sufix].to_s) unless defaults[:menu_sufix].nil?

    inactive_class = menu_name + '-inactive'
    inactive_class += ('-' + defaults[:menu_sufix].to_s) unless defaults[:menu_sufix].nil?

    show_name = defaults[:show_prefix].nil? ? defaults[:name].to_s : (defaults[:show_prefix].to_s + "-" + defaults[:name].to_s)

    template =  %q{
<b>
  <span id="<%= menu_name %>">
    <% all.each do |active, name| %>
      <span id="<%= menu_name %>-<%= active %>" <%= " style='display:none'" unless active == show %> >

        <% all.each do |element, text| %>

          <% if active == element %>
            <span class="<%= active_class %>">
              <%= text.to_s %>
            </span>
          <% else %>
            <span class="<%= inactive_class %>">
              <a href="#" onclick="Element.show('<%= show_name + '-' + element.to_s %>'); Element.hide('<%= show_name + '-' + active.to_s %>'); Element.show('<%= menu_name + '-' + element.to_s %>'); Element.hide('<%= menu_name + '-' + active.to_s %>');">
                <%= text.to_s %>
              </a>
            </span>
          <% end %>

        <% end %>
      </span>
    <% end %>
  </span>
</b>
    }
    erb = ERB.new(template)
    return erb.result(binding)
  end


  private


  def get_date_start_field_name(name)
    "#{name.gsub(/_/, '-')}-start"
  end

  def get_date_end_field_name(name)
    "#{name.gsub(/_/, '-')}-end"
  end

end
