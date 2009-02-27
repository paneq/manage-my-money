require 'test_helper'
require 'hash'

class InteligoParserTest < Test::Unit::TestCase

  def setup
    save_rupert
    
    @rupert.categories << Category.new(:name => 'Inteligo', :description =>'inteligo rachunek glowny')
    @rupert.save!
    @inteligo = @rupert.categories(true).find_by_name 'Inteligo'
    assert_not_nil @inteligo
  end


  def test_parse

    InteligoParser.parse(open(RAILS_ROOT + '/test/files/inteligo.xml'), @rupert, @inteligo)
  end

end