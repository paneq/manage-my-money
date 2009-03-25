module ExchangesHelper
  def js_var(e)
    "#{e.left_currency.long_symbol.downcase}_#{e.right_currency.long_symbol.downcase}_conversion"
  end

  def link_to_add_exchange(e, form_id)
    link_to_add "#{e.left_currency.long_symbol} - #{e.right_currency.long_symbol}", "##{js_var(e)}", :rel => form_id + 'conversions'
  end
end
