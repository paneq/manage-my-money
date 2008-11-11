# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'hash_enums'


class HashEnumsTest < ActiveSupport::TestCase



  

  def test_has_define_enum_method
    temporary = Class.new do
      extend HashEnums
    end
    assert(temporary.protected_methods(false).include?("define_enum"), "No define_enum method defined.")
  end

  

  def test_has_enum_methods
    temporary2 = Class.new do
      extend HashEnums
      define_enum :my_enum, {:type=>1}
    end
    t = temporary2.new
    assert(t.respond_to?(:my_enum), "No enum getter defined")
    assert(t.respond_to?(:my_enum=), "No enum setter defined")
    assert(temporary2.methods.include?("MY_ENUMS"), "No enum list getter defined")
  end

   
  def test_enum_methods1

    temporary3 = Class.new do
      extend HashEnums
      attr(:my_enum_int, true)
      define_enum :my_enum, {:type=>1}
    end


    t = temporary3.new
    assert_equal(nil, t.my_enum)

    t.my_enum = :type

    assert_equal(:type, t.my_enum)
    assert_equal(1, t.my_enum_int)
    assert_equal({:type=>1}, temporary3.MY_ENUMS)

  end


  def test_enum_methods2

    temporary4 = Class.new do
      extend HashEnums
      attr(:my_enum_, true)
      define_enum :my_enum, {:type=>1, :test=>2}, {:attr_suffix => '_'}
    end


    t = temporary4.new
    assert_equal(nil, t.my_enum)

    t.my_enum = :type

    assert_equal(:type, t.my_enum)
    assert_equal(1, t.my_enum_)
    assert_equal({:type=>1, :test=>2}, temporary4.MY_ENUMS)

    t.my_enum = :test
    assert_equal(:test, t.my_enum)
    assert_equal(2, t.my_enum_)

  end

 def test_enum_methods3

    temporary5 = Class.new do
      extend HashEnums
      attr(:blabla, true)
      define_enum :my_enum, {:type=>1}, {:attr_name => "blabla"}
    end


    t = temporary5.new
    assert_equal(nil, t.my_enum)

    t.my_enum = :type

    assert_equal(:type, t.my_enum)
    assert_equal(1, t.blabla)
    assert_equal({:type=>1}, temporary5.MY_ENUMS)

  end

end
