  module Forms::ApplicationHelper

  ##
  # Helper generujacy pole typu select dla podanego atrybutu typu 'enum' utworzonego przy pomocy metody define_enum w module HashEnums
  #
  # Parametry:
  # method - nazwa pola w klasie
  # options - standardowe hash z opcjami, Uwaga: opcje html nalezy przekazac w hashu options pod kluczem :html_options, a nie jako dodatkowy parametr helpera
  #
  # Założenia
  #  - dla widoku dostepna jest zmienna instancji zawierajaca kody dostepnych opcji, o nazwie wskazanej w parametrze 'method' ale w liczbie mnogiej
  #    Jeśli zmienna nie jest dostępna używane są wszystkie wartoścu enum zdefiniowane w danej klasie modelu (zdognie z dokumentacja HashEnums)
  #  - dla widoku dostepna jest metoda zwracajaca opis dla kazdej opcji, postaci
  #       def get_desc_for_#{method}(option_name)
  #       end
  #    Jesli metoda nie jest dostepna, wartosc danej opcji staje sie jednoczesnie jej opisem.
  #
  # Przyklad:
  # f.enum_select :transaction_amount_limit_type
  # wygeneruje nam to samo co użycie:
  # f.select :transaction_amount_limit_type, User.TRANSACTION_AMOUNT_LIMIT_TYPES.keys.map { |type| [get_desc_for_transaction_amount_limit_type(type), type] }
  #
  # @author jPlebanski
  def enum_select(object, method, options = {})

    object_class = object.camelcase.constantize
    enum_values = instance_variable_get("@#{method.to_s.pluralize}") || object_class.const_get(method.to_s.pluralize.upcase.intern).keys

    description_method = "get_desc_for_#{method.to_s}".intern
    should_get_description = respond_to? description_method

    choices = if should_get_description
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
