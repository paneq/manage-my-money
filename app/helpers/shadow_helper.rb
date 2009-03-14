module ShadowHelper


  # Creates a table that includes elements created in block and
  # surrounds them with inner shadow
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  #
  # ==== Examples
  #
  # inner_shadow do
  #   <div>sth</div>
  # end
  #
  # inner_shadow :top, :bottom) do
  #   <div>Div without top and bottom inner shadow</div>
  # end
  #
  # inner_shadow :left, :style => "background-color: white;") do
  #   <div>This element will has white background</div>
  # end
  #
  # inner_shadow :left, {:id => 'shadow-table-without-left-shadow'}, {:style => "background-color: white;", :id => 'inner-td-of-shadowed-table'}) do
  #   <div>This element will has white background</div>
  # end
  def inner_shadow(*args, &block)
    inner_or_outer_shadow(:inner, '80grey', *args, &block)
  end


  def light_shadow(*args, &block)
    shadow('60blue', *args, &block)
  end


  def strong_shadow(*args, &block)
    shadow('80grey', *args, &block)
  end

  alias_method :dark_shadow, :strong_shadow
  
  # Creates a table that includes elements created in block and
  # surrounds them with outer shadow
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  #
  # ==== Examples
  #
  # shadow('80grey' do
  #   <div>sth</div>
  # end
  #
  # shadow('80grey', :top, :bottom) do
  #   <div>Div without top and bottom shadow</div>
  # end
  #
  # shadow('60blue', :left, :style => "background-color: white;") do
  #   <div>This element will has white background</div>
  # end
  #
  # shadow('60blue', :left, {:id => 'shadow-table-without-left-shadow'}, {:style => "background-color: white;", :id => 'inner-td-of-shadowed-table'}) do
  #   <div>This element will has white background</div>
  # end
  def shadow(*args, &block)
    inner_or_outer_shadow(:outer, *args, &block)
  end


  private

  # inner_or_outer_shadow(:inner, '80grey', :left, :right ... table-options, element-options
  # inner_or_outer_shadow(:outer, '60blue' ... element-options
  def inner_or_outer_shadow(*args, &block)
    type = args.shift

    type = case type
    when :inner then 'inner-shadow'
    when :outer then 'shadow'
    else raise 'Unknown shadow type'
    end

    style = args.shift
    raise 'Wrong argument' unless style.is_a? String

    content_options = args.extract_options!
    table_options = args.extract_options!

    table_options[:class] ||= 'shadow'
    content_options[:class] ||= 'mm-shadow'
    raise 'No block given when required' unless block_given?

    top = !args.include?(:top)
    bottom = !args.include?(:bottom)
    left = !args.include?(:left)
    right = !args.include?(:right)

    text = ''

    #top
    if top
      tr = ''
      tr << "<td class=\"tl-#{type}-#{style} shadow-x shadow-y\"> </td>" if left
      tr << "<td class=\"tm-#{type}-#{style} shadow-x\"> </td>"
      tr << "<td class=\"tr-#{type}-#{style} shadow-x shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    #middle
    begin
      tr = ''
      tr << "<td class=\"ml-#{type}-#{style} shadow-y\"> </td>" if left
      tr << content_tag(:td, capture(&block), content_options)
      tr << "<td class=\"mr-#{type}-#{style} shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    if bottom
      tr = ''
      tr << "<td class=\"bl-#{type}-#{style} shadow-x shadow-y\"> </td>" if left
      tr << "<td class=\"bm-#{type}-#{style} shadow-x\"> </td>"
      tr << "<td class=\"br-#{type}-#{style} shadow-x shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    #concat "<table class=\"shadow\" > #{text} </table>"
    concat content_tag(:table, text, table_options)
  end
end