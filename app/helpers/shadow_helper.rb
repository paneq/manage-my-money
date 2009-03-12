module ShadowHelper
  
  # Creates a table that includes elements created in block and
  # surrounds them with shadow
  #
  # ==== Signatures
  #
  # shadow(*exclude_array) do
  #   # some text, div, span, table, whatever
  # end
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  def shadow(*exclude_array, &block)
    raise 'No block given when required' unless block_given?

    top = !exclude_array.include?(:top)
    bottom = !exclude_array.include?(:bottom)
    left = !exclude_array.include?(:left)
    right = !exclude_array.include?(:right)

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
      tr << "<td class=\"mm-shadow\">#{capture(&block)}</td>"
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

    concat "<table class=\"shadow\" > #{text} </table>"
  end
end