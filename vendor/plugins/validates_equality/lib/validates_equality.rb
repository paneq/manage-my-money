# ValidatesEquality
module ValidatesEquality

  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods

    # Options:
    # * <tt>:raise_nil_in_chain</tt> - If set to true exception is raise when any association is nil
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

      #make always an array, reverse for easy push and pop
      attr_paths.map!{|element| element.is_a?(Array) ? element.reverse : [element]}
      
      #TODO: Raise if elements is empty array. that would mean checking attribute in a model with the attribute itself.

      send(validation_method(options[:on] || :save), options) do |record|
        options[:compare_value] = record.send(options[:compare_to])
        options[:record] = record
        attr_paths.each do |attr_path|
          check_equality(attr_path.clone, record, options)
        end
      end

    end # validates_equality


    def check_equality(attr_path, objects, options)
      objects = [objects] unless objects.is_a?(Array)
      
      if attr_path.empty?
        objects.each do |element|
          compare_with_error(element, options)
        end
      else
        attr_name = attr_path.pop
        objects.each do |element|
          association = element.send(attr_name)
          unless association.nil?
            check_equality(attr_path, association, options)
          else
            raise "element.#{attr_name} is nil, where element.class is #{element.class.to_s}. Element inspect: #{element.inspect}" if options[:raise_nil_in_chain]
          end
        end
        attr_path.push(attr_name)
      end

    end # check_equality


    def compare_with_error(object, options)
      attr_name = options[:compare_to]
      value = object.send(attr_name)
      return if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
      unless options[:compare_value] == value
        options[:record].errors.add(attr_name, :invalid, :default => options[:message])
      end
    end


    # Options:
    # * <tt>:raise_nil_in_chain</tt> - If set to true exception is raise when any association is nil
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
