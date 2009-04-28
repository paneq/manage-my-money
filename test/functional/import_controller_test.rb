require 'test_helper'

class ImportControllerTest < ActionController::TestCase

  def setup
    save_jarek
    prepare_sample_catagory_tree_for_jarek
    log_user(@jarek)
  end


  test "Should see import page" do
    get :import
    assert_response :success
    assert_template 'import'
    assert_select 'input#file', :count => 2
  end


  test "Import gnucash" do
    post :parse_gnucash, 
      :file => fixture_file_upload('../files/gnucash_empty_with_transfers.xml', 'text/xml')

    assert_response :success
    assert_template 'import_status'
    assert_select 'div#parsing-good'

  end

  test "Import gnucash with warnings" do
    post :parse_gnucash,
      :file => fixture_file_upload('../files/gnucash_full_with_warnings.xml', 'text/xml')

    assert_response :success
    assert_template 'import_status'
    assert_select 'div#parsing-good'

    assert_select "ul#category-error li", :count => 1
    assert_select "ul#transfer-error li", :count => 4
   end



  test "Import bad gnucash" do
    post :parse_gnucash,
      :file => fixture_file_upload('../files/gnucash_bad.xml', 'text/xml')

    assert_response :success
    assert_template 'import_status'
    assert_select 'div#parsing-error'
  end

end
