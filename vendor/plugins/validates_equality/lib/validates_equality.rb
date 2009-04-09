# ValidatesEquality
module ValidatesEquality

  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods

    # Options:
    # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>).
    # * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
    # * <tt>:allow_blank</tt> - Skip validation if attribute is blank.
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_equality(compare_to, *attr_paths)
      options = { :allow_nil => false }
      options.update(attr_paths.extract_options!.symbolize_keys)
      options[:compare_to] = compare_to.to_sym
      
      attr_paths.map!{|element| element.is_a?(Array) ? element : [element]}

      send(validation_method(options[:on] || :save), options) do |record|
        compare_value = record.send(options[:compare_to])
        attr_paths.each do |attr_path|
          check_equality(compare_value, attr_path, record, options)
        end
      end

    end # validates_equality


    def check_equality(compare_value, attr_path, objects, options)
      objects = [objects] unless objects.is_a?(Array)
      
      if attr_path.empty?
        objects.each do |element|
          compare_with_error(compare_value, element, options)
        end
      else
        attr_name = attr_path.shift
        objects.each do |element|
          check_equality(compare_value, attr_path.clone, element.send(attr_name), options)
        end
      end

    end # check_equality


    def compare_with_error(compare_value, object, options)
      attr_name = options[:compare_to]
      value = object.send(attr_name)
      return if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
      unless compare_value == value
        object.errors.add(attr_name, :invalid, :default => options[:message])
      end
    end


    # Options:
    # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>).
    # * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
    # * <tt>:allow_blank</tt> - Skip validation if attribute is blank.
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
    #   method, proc or string should return or evaluate to a true or false value.
    def validates_user_id(*attr_paths)
      validates_equality(:user_id, *attr_paths)
    end

  end # ClassMethods
  
end # ValidatesEquality
