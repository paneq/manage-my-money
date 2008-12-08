module HashEnums
  protected
  ## definiuje pole typu enum w klasie modelu (getter i setter w obiekcie, oraz stala na poziomie klasy z dostepnymi typami
  # enum - symbol, nazwa gettera i settera
  # types - tablica symboli dostepnych typow, lub hash dostepnych typow i ich wartosci numerycznych
  # options - hash opcji ustalajacych nazwe pola w bazie danych: :attr_suffix, :attr_prefix, :attr_name
  #
  # Przyklad:
  # Definiujemy klase
  #
  # class User < ActiveRecord::Base
  #   extend HashEnums
  #   define_enum :transaction_amount_limit_type, [:transaction_count,
  #                                                :week_count,
  #                                                :actual_month,
  #                                                :actual_and_last_month
  #                                               ]
  # end
  #
  # Metoda define_enum dodaje do klasy User metode statyczna TRANSACTION_AMOUNT_LIMIT_TYPES
  # ktora zwraca w wyniku hash z symbolami tworzacymi typ wyliczeniowy oraz z przypisanymi do nich wartosciami liczbowymi
  # W powyzszym przykladzie zakladamy ze kolumna bazy danych w ktorej przechowywana jest wartosc enum ma nazwe 'transaction_amount_limit_type_int'
  # i jest typu integer.
  #
  # Dodatkowo instancje klasy User otrzymuja metody 'transaction_amount_limit_type=(symbol)' oraz 'transaction_amount_limit_type'
  # sluzace odpowiednio do zmiany i pobierania wartosci enum (operuja na symbolach z TRANSACTION_AMOUNT_LIMIT_TYPES)
  # Proba przypisania symbolu z poza zdefiniowanego zbioru powoduje rzucenie wyjatku.
  #
  #
  #
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

    #konwertowanie tabeli na hash
    types = nil
    if types_array_or_hash.instance_of?(Array)
      types = {}
      types_array_or_hash.each_with_index { |type_name, type_value| types[type_name] = type_value }
    else
      types = types_array_or_hash
    end

    const_set(types_const_name, types)

    #definicja settera obiektu
    define_method((enum.to_s + '=').intern) do |a_type|

      a_type = a_type.instance_of?(String) ? a_type.intern : a_type #a_type musi być symbolem - konwersja jest potrzebna kiedy wartośc przychodzi z formularza
      unless types[a_type]
        raise "Unknown enum value: " + a_type.to_s
      else
        self.send(attr_name + "=", types[a_type])
      end
    end

    #definicja gettera obiekt
    define_method(enum) do
      type = self.send(attr_name)
      types.invert[type]
    end

    #definiowanie gettera do hasha z mozliwymi wartosciami enum na poziomie Klasy
    class_eval <<-EVAL
      def self.#{(types_const_name)}
          #{types_const_name}
      end
    EVAL


  end
end
