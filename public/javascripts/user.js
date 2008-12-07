show_or_hide_transaction_limit_value = function(){
  if ($('user_transaction_amount_limit_type').value == 'transaction_count' || $('user_transaction_amount_limit_type').value == 'week_count') {
    $('user_transaction_amount_limit_value').show();
  } else {
    $('user_transaction_amount_limit_value').hide();
  }
}