module LinkActionHelper
  include ImageHelper

  # Generates helper methods for creating links as images for some actions on given object
  # link_to_new
  # link_to_show(obj)
  # link_to_edit(obj)
  # link_to_destroy(obj)
  [:new, :show, :edit, :destroy].each do |action|
    default = {:title => I18n.translate(action)}
    default.merge!(:confirm => 'Czy na pewno usunąć ?', :method => :delete, :title => 'Usuń') if action == :destroy
    define_method('link_to_' + action.to_s) do |*args|
      obj = args.shift
      options = args.shift
      options ||= {}
      link_to send(action.to_s + '_img'), underscore(action, obj), {:id => shortcut(action, obj)}.merge(default).merge(options)
    end
  end


  private

  
  def underscore(action_name, obj)
    tmp = obj.class.name.underscore + '_path'
    tmp = 'edit_' + tmp if action_name == :edit
    if action_name == :new
      tmp = 'new_' + tmp
      send(tmp)
    end
    send(tmp, obj)
  end

  def shortcut(action_name, obj)
    action_name = action_name.to_s[0..3]
    "#{action_name}-#{obj.class.name.underscore[0..2]}-#{obj.id}"
  end
end
