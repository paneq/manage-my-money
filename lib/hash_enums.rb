module HashEnums
  protected
  ## definiuje pole typu enum w klasie modelu (getter i setter w obiekcie, oraz stala na poziomie klasy z dostepnymi typami
  # enum - symbol, nazwa gettera i settera
  # types - tablica symboli dostepnych typow, lub hash dostepnych typow i ich wartosci numerycznych
  # options - hash opcji ustalajacych nazwe pola w bazie danych: :attr_suffix, :attr_prefix, :attr_name
  # author - JP
  def define_enum(enum, types_array_or_hash, options = nil)
    suffix = '_int'
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

    types = nil
    if types_array_or_hash.instance_of?(Array)
      types = {}
      types_array_or_hash.each_with_index { |type_name, type_value| types[type_name] = type_value }
    else
      types = types_array_or_hash
    end

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
