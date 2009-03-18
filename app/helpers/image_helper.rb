module ImageHelper
  # Generates helper methods for proper action images
  # new_img
  # show_img
  # edit_img
  # destroy_img
  [:new, :show, :edit, :destroy].each do |action|
    define_method(action.to_s + '_img') do
      image_tag("/images/actions/#{action}.png", :size => '20x20', :style => 'margin: 3px;')
    end
  end

end
