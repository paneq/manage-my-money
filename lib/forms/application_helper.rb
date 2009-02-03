  module Forms::ApplicationHelper

  ##
  # Helper generujacy pole typu select dla podanego atrybutu typu 'enum' utworzonego przy pomocy metody define_enum w module HashEnums
  #
  # Parametry:
  # method - nazwa pola w klasie
  # options - standardowe hash z opcjami, Uwaga: opcje html nalezy przekazac w hashu options pod kluczem :html_options, a nie jako dodatkowy parametr helpera
  # options[:values] - tablica symboli dostępnych wyborów, mozna tez podac hash postaci {:symbol => 'opis'}
  #
  # Założenia
  #  - jesli options[:values] nie jest podane metoda próbuje znaleźć listę wyboru ze zmiennej instancji kontrolera, o nazwie wskazanej w parametrze 'method' ale w liczbie mnogiej
  #    Jeśli zmienna nie jest dostępna używane są wszystkie wartoścu enum zdefiniowane w danej klasie modelu (zdognie z dokumentacja HashEnums)
  #  - dla widoku dostepna jest metoda zwracajaca opis dla kazdej opcji, postaci
  #       def get_desc_for_#{method}(option_name)
  #       end
  #    (taka metoda moze znalezc sie w helperze danego kontrolera, lub ApplicationHelperze)
  #    Jesli metoda nie jest dostepna, wartosc danej opcji staje sie jednoczesnie jej opisem.
  #
  # Przyklad:
  # f.enum_select :transaction_amount_limit_type
  # wygeneruje nam to samo co użycie:
  # f.select :transaction_amount_limit_type, User.TRANSACTION_AMOUNT_LIMIT_TYPES.keys.map { |type| [get_desc_for_transaction_amount_limit_type(type), type] }
  #
  # @author jPlebanski
  def enum_select(object, method, options = {})

    object_name = (options[:class] || object).to_s
    object_class = object_name.camelcase.constantize
    enum_values = options[:values] || instance_variable_get("@#{method.to_s.pluralize}") || object_class.const_get(method.to_s.pluralize.upcase.intern).keys

    description_method = "get_desc_for_#{method.to_s}".intern
    should_get_description = respond_to? description_method

    choices = if enum_values.is_a? Hash
        enum_values.collect { |key, desc|  [desc, key] }
      elsif should_get_description
        enum_values.map do |type|
          [send(description_method, type), type]
        end
      else
        enum_values.map do |type|
          [type, type]
        end
    end
    select object, method, choices, options, options[:html_options] || {}
  end

  #TODO: enum_radio


  end
