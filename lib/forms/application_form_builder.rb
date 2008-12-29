class Forms::ApplicationFormBuilder < ActionView::Helpers::FormBuilder
    # Copied from FormBuilder. FormBuilder looks like it has some bright
    # engineering ideas but never finished implementing them. This *should*
    # be automated by defining "self.field_helpers", but it's used before
    # this class is loaded.
    Forms::ApplicationHelper.instance_methods.each do |selector|
      src = <<-end_src
        def #{selector}(method, options = {})
          @template.send(#{selector.inspect}, @object_name, method, objectify_options(options))
        end
      end_src
      class_eval src, __FILE__, __LINE__
    end
   
    private
   
    def objectify_options(options)
      @default_options.merge(options.merge(:object => @object))
    end
  end
