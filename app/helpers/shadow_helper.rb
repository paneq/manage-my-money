module ShadowHelper
  
  # Creates a table that includes elements created in block and
  # surrounds them with shadow
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  #
  # ==== Examples
  #
  # shadow do
  #   <div>sth</div>
  # end
  #
  # shadow(:top, :bottom) do
  #   <div>sth</div>
  # end
  #
  # shadow(:left, :style => "background-color: white;") do
  #   <div>This element will has white background</div>
  # end
  #
  # shadow(:left, {:id => 'shadow-table-without-left-shadow'}, {:style => "background-color: white;", :id => 'inner-td-of-shadowed-table'}) do
  #   <div>This element will has white background</div>
  # end

  def shadow(*args, &block)
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
      tr << "<td class=\"tl-shadow shadow-x shadow-y\"> </td>" if left
      tr << "<td class=\"tm-shadow shadow-x\"> </td>"
      tr << "<td class=\"tr-shadow shadow-x shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    #middle
    begin
      tr = ''
      tr << "<td class=\"ml-shadow shadow-y\"> </td>" if left
      tr << content_tag(:td, capture(&block), content_options)
      tr << "<td class=\"mr-shadow shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    if bottom
      tr = ''
      tr << "<td class=\"bl-shadow shadow-x shadow-y\"> </td>" if left
      tr << "<td class=\"bm-shadow shadow-x\"> </td>"
      tr << "<td class=\"br-shadow shadow-x shadow-y\"> </td>" if right
      text << "<tr>#{tr}</tr>"
    end

    #concat "<table class=\"shadow\" > #{text} </table>"
    concat content_tag(:table, text, table_options)
  end
end