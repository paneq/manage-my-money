# To change this template, choose Tools | Templates
# and open the template in the editor.

module HashEnums
  def define_enum(enum, types, options = nil)
    suffix = '_val'
    prefix = ''

    if options
      if options[:attr_suffix]
        suffix = options[:attr_suffix]
      end

      if options[:attr_prefix]
        prefix = options[:attr_prefix]
      end
    end

    if options && options[:attr_name]
      attr_name = options[:attr_name]
    else
      attr_name = prefix + enum.to_s + suffix
    end

    types_const_name = enum.to_s.pluralize.upcase.intern

    const_set(types_const_name, types)

    define_method((enum.to_s + '=').intern) do |a_type|

      unless types[a_type]
        raise "Unknown type: " + a_type.to_s
      else
        self.send(attr_name + "=", types[a_type])
      end
    end

    define_method(enum) do
      type = self.send(attr_name)
      types.invert[type]
    end

    class_eval <<EVAL
      def self.#{(types_const_name)}
          #{types_const_name}
      end
EVAL

  end
end
