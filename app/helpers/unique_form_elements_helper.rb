module UniqueFormElementsHelper
  def form_element_uid(form)
    "#{form.object_name.to_s.gsub(/[\[\]]+/,'_')}_#{form.object.new_record? ? 'new' : form.object.id.to_s}_#{form.object.object_id.abs}_#{Time.now.to_s(:number)}_"
  end
end
