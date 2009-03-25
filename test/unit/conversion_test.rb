require 'test_helper'

class ConversionTest < ActiveSupport::TestCase

  def setup
    save_rupert
  end


  #  test "Create new conversions with new exchange" do
  #    c = Conversion.new(:exchange_attributes => {
  #        :user_id => @rupert.id,
  #        :left_currency_id => @zloty.id,
  #        :right_currency_id => @euro.id,
  #        :left_to_right => 0.25,
  #        :right_to_left => 4
  #      })
  #    assert c.valid?
  #    assert_not_nil c.exchange
  #
  #  end


  test "Create new conversions with existing exchange" do
    e = Exchange.new({
        :user_id => @rupert.id,
        :left_currency_id => @zloty.id,
        :right_currency_id => @euro.id,
        :left_to_right => 0.25,
        :right_to_left => 4,
        :day => Date.today
      })
    assert e.save

    #  It does not work this way!
    #  c = Conversion.new(:exchange_attributes => {
    #      :id => e.id,
    #      :user_id => e.user_id,
    #      :left_currency_id => e.left_currency_id,
    #      :right_currency_id => e.right_currency_id,
    #      :left_to_right => e.left_to_right,
    #      :right_to_left => e.right_to_left
    #    })
    #  c.valid?
    #  puts c.errors.full_messages
    #  assert c.valid?
    #  assert_not_nil c.exchange


    c = Conversion.new(:exchange_id => e.id)
    c.valid?
    assert c.valid?
    assert_not_nil c.exchange
  end


  test "Create new conversions with existing exchange to edit" do
    e = Exchange.new({
        :user_id => @rupert.id,
        :left_currency_id => @zloty.id,
        :right_currency_id => @euro.id,
        :left_to_right => 0.25,
        :right_to_left => 4,
        :day => Date.today
      })
    assert e.save

    c = Conversion.new(:exchange_id => e.id, :exchange_attributes => {
        :id => e.id,
        :user_id => e.user_id,
        :left_currency_id => e.left_currency_id,
        :right_currency_id => e.right_currency_id,
        :left_to_right => 0.1,
        :right_to_left => 10
      })
    c.valid?
    assert c.valid?
    assert_not_nil c.exchange
    assert_equal 10, c.exchange.right_to_left
  end

end
