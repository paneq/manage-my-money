class SqlDialects

  class << self

    SYMBOLS = {
      :postgresql => {
        :true => 't',
        :false => 'f',
        :today => 'current_date'
      },
      :sqlite3 => {
        :true => '1',
        :false => '0',
        :today => "julianday('now', 'start of day')"
      }
    }


    def get_true
      check_symbol(:true)
    end

    def get_false
      check_symbol(:false)
    end

    def get_today
      check_symbol(:today)
    end


    def get_date(date)
      case adapter_name
      when :postgresql then date
      when :sqlite3 then "julianday(#{date})"
      else throw "Unknown adapter #{adapter_name.to_s}"
      end
    end

    private
    def adapter_name
      @adapter ||= ActiveRecord::Base.configurations[RAILS_ENV]['adapter'].intern
    end

    def check_symbol(sym_name)
      sym = SYMBOLS[adapter_name][sym_name]
      throw "Unknown symbol #{sym_name.to_s} for adapter #{adapter_name.to_s}" if sym.nil?
      sym
    end

  end

end
