module DynamicFormsHelper

  NEW_RECORD = 'NEW_RECORD'

  def remove_link_unless_new_record(fields)
    remove_link(fields, true)
  end

  def remove_link(fields, new_record_check = false)
    out = ''
    out << fields.hidden_field(:_delete)  unless new_record_check && !fields.object.new_record?
    out << link_to("Usuń", "##{fields.object.class.name.underscore}", :class => 'remove')
    out
  end

  # This method demonstrates the use of the :child_index option to render a
  # form partial for, for instance, client side addition of new nested
  # records.
  #
  # This specific example creates a link which uses javascript to add a new
  # form partial to the DOM.
  #
  #   <% form_for @project do |project_form| -%>
  #     <div id="tasks">
  #       <% project_form.fields_for :tasks do |task_form| %>
  #         <%= render :partial => 'task', :locals => { :f => task_form } %>
  #       <% end %>
  #     </div>
  #   <% end -%>


  def generate_html(form_builder, method, obj_options={}, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(method).klass.new(obj_options)
    options[:partial] ||= method.to_s.singularize
    options[:form_builder_local] ||= :f

    form_builder.fields_for(method, options[:object], :child_index => NEW_RECORD) do |f|
      render(:partial => options[:partial], :locals => { options[:form_builder_local] => f })
    end

  end


  def generate_template(form_builder, method, obj_options = {}, options = {})
    # we use auto_complete_field in generated HTML, which means that it will contains some javascript.
    #
    # This java script is generated with JavaScriptHelper and uses those two methods:
    #
    # javascript_tag
    # javascript_cdata_section
    #
    # Because of that the JS script that is in HTML is surrounded by given lines:
    # //<![CDATA[
    #   bla bla
    # //]]>
    #
    # But we are going to put our JS code in header in a place that is already surrounded by such lines
    # so we need to escape it from HTML code so it does not break our first CDATA.

    html = generate_html(form_builder, method, obj_options, options)
    html.gsub!(Regexp.new(Regexp.escape("//<![CDATA[")), '')
    html.gsub!(Regexp.new(Regexp.escape("//]]>")), '')
    escape_javascript html
  end

end
