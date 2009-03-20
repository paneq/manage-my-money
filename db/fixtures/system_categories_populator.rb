class SystemCategoriesPopulator < DataPopulator
  class << self

    #155 system categories total (including 2 commented out)

    def load_data
      create_asset
      create_expense
      create_income
      create_loan
      #      create_balance
    end


    protected

    def create_asset
      n(:id => 1, :name => 'Zasoby', :category_type => :ASSET) do |c|
        c << n(:id => 101, :name => 'Fundusze') do |c|
          c << n(:id => 10101, :name => 'Fundusze zrównoważone')
          c << n(:id => 10102, :name => 'Fundusze obligacji')
          c << n(:id => 10103, :name => 'Fundusze akcji')
          c << n(:id => 10104, :name => 'Fundusze stabilnego wzrostu')
          c << n(:id => 10105, :name => 'Fundusze pieniężne')
          c << n(:id => 10106, :name => 'Fundusze zagraniczne')
        end

        c << n(:id => 102, :name => 'Konta bankowe') do |c|
          c << n(:id => 10201, :name => 'Rachunki bieżące')
          c << n(:id => 10202, :name => 'Konta oszczędnościowe')
        end

        c << n(:id => 103, :name => 'Gotówka') do |c|
          c << n(:id => 10301, :name => 'Portfel')
          c << n(:id => 10302, :name => "'Skarpeta'")
        end

        c << n(:id => 104, :name => 'Konta wirtualne') do |c|
          c << n(:id => 10401, :name => 'Paypal')
        end

        #c << n(:id => 116, :name => 'Nieruchomości')

        c << n(:id => 105, :name => 'Lokaty')

      end
    end

    def create_income
      n(:id => 2, :name => 'Przychody', :category_type => :INCOME) do |c|
        c << n(:id => 201, :name => 'Zyski z inwestycji')
        c << n(:id => 202, :name => 'Wynagrodzenie')
        c << n(:id => 203, :name => 'Premia')
        c << n(:id => 204, :name => 'Darowizny i spadki')
        c << n(:id => 205, :name => 'Wygrane')
        c << n(:id => 206, :name => 'Otrzymane prezenty')
      end
    end


    def create_expense
      n(:id => 3,  :name => 'Wydatki', :category_type => :EXPENSE) do |c|
        c << n(:id => 301, :name => 'Opłaty bankowe')

        c << n(:id => 302, :name => 'Samochód') do  |c|
          c << n(:id => 30201, :name => 'Naprawy i części')
          c << n(:id => 30202, :name => 'Kosmetyka')
          c << n(:id => 30203, :name => 'Opłaty stałe')
          c << n(:id => 30204, :name => 'Wyposażenie')
          c << n(:id => 30205, :name => 'Paliwo')
          c << n(:id => 30206, :name => 'Parking')
        end

        c << n(:id => 303, :name => 'Dobroczynność')

        c << n(:id => 304, :name => 'Ubrania') do |c|
          c << n(:id => 30401, :name => 'Czyszczenie')
          c << n(:id => 30402, :name => 'Naprawa')
          c << n(:id => 30403, :name => 'Konserwacja')
        end

        c << n(:id => 305, :name => 'Kultura i rozrywka') do |c|
          c << n(:id => 30501, :name => 'Koncerty')
          c << n(:id => 30502, :name => 'Kino')
          c << n(:id => 30503, :name => 'Teatr i opera')
          c << n(:id => 30504, :name => 'Sport')
          c << n(:id => 30505, :name => 'Wypoczynek')
          c << n(:id => 30506, :name => 'Podróże i noclegi')
          c << n(:id => 30507, :name => 'Imprezy i wydarzenia')
          c << n(:id => 30508, :name => 'Gry')
          c << n(:id => 30509, :name => 'Książki')
          c << n(:id => 30510, :name => 'Prasa')
          c << n(:id => 30511, :name => 'Muzyka')
        end

        c << n(:id => 306, :name => 'Podarunki')

        c << n(:id => 307, :name => 'Jedzenie') do |c|
          c << n(:id => 30701, :name => 'Art. spożywcze') do |c|
            c << n(:id => 3070101, :name => 'Owoce')
            c << n(:id => 3070102, :name => 'Warzywa')
            c << n(:id => 3070103, :name => 'Mięso')
            c << n(:id => 3070104, :name => 'Nabiał') do |c|
              c << n(:id => 307010401, :name => 'Sery')
              c << n(:id => 307010402, :name => 'Mleko')
              c << n(:id => 307010403, :name => 'Jogurty')
            end
            c << n(:id => 3070105, :name => 'Napoje') do |c|
              c << n(:id => 307010501, :name => 'Woda')
              c << n(:id => 307010502, :name => 'Gazowane')
              c << n(:id => 307010503, :name => 'Soki')
              c << n(:id => 307010504, :name => 'Kawa i herbata')
              c << n(:id => 307010505, :name => 'Alkohol') do |c|
                c << n(:id => 307010506, :name => 'Piwo')
                c << n(:id => 307010507, :name => 'Wino')
                c << n(:id => 307010508, :name => 'Wódka')
                c << n(:id => 307010509, :name => 'Whisky')
              end
            end
          end
          c << n(:id => 30702, :name => 'Słodycze i przekąski')

        end
        c << n(:id => 308, :name => 'Fast food')
        c << n(:id => 309, :name => 'Bary mleczne')
        c << n(:id => 310, :name => 'Bary wegetariańskie')
        c << n(:id => 311, :name => 'Restauracja, kawiarnia, pub')

        c << n(:id => 312, :name => 'Transport') do |c|
          c << n(:id => 31201, :name => 'Przejazdy pociągiem')
          c << n(:id => 31202, :name => 'Przeloty')
          c << n(:id => 31203, :name => 'Komunikacja wodna')
          c << n(:id => 31204, :name => 'Komunikacja autobusowa')
          c << n(:id => 31205, :name => 'Komunikacja miejska')
          c << n(:id => 31206, :name => 'Taxi')
          c << n(:id => 31207, :name => 'Samochód') do |c|
            c << n(:id => 3120701, :name => 'Paliwo')
            c << n(:id => 3120702, :name => 'Parking')
          end
        end


        c << n(:id => 313, :name => 'Komputer') do |c|
          c << n(:id => 31301, :name => 'Części')
          c << n(:id => 31302, :name => 'Akcesoria')
          c << n(:id => 31303, :name => 'Oprogramowanie')
          c << n(:id => 31304, :name => 'Gry')
          c << n(:id => 31305, :name => 'Naprawy')
        end

        c << n(:id => 314, :name => 'Edukacja') do |c|
          c << n(:id => 31401, :name => 'Czesne')
          c << n(:id => 31402, :name => 'Materiały naukowe')
        end

        c << n(:id => 315, :name => 'Zdrowie') do |c|
          c << n(:id => 31501, :name => 'Leki')
          c << n(:id => 31502, :name => 'Profilaktyka')
          c << n(:id => 31503, :name => 'Lekarz')
        end

        c << n(:id => 316, :name => 'Hobby')
      
        c << n(:id => 317, :name => 'Usługi online') do |c|
          c << n(:id => 31701, :name => 'Hosting')
          c << n(:id => 31702, :name => 'Domeny')
        end

        c << n(:id => 318, :name => 'Higiena osobista')
      
        c << n(:id => 319, :name => 'Elektronika') do |c|
          c << n(:id => 31901, :name => 'AGD')
          c << n(:id => 31902, :name => 'RTV')
        end

        c << n(:id => 320, :name => 'Dom i ogród') do |c|
          c << n(:id => 32001, :name => 'Środki czystości')
          c << n(:id => 32002, :name => 'AGD')
          c << n(:id => 32003, :name => 'RTV')
          c << n(:id => 32004, :name => 'Meble')
          c << n(:id => 32005, :name => 'Akcesoria')
          c << n(:id => 32006, :name => 'Ogród')
          c << n(:id => 32007, :name => 'Czynsz')
          c << n(:id => 32008, :name => 'Woda')
          c << n(:id => 32009, :name => 'Prąd')
          c << n(:id => 32010, :name => 'Gaz')
        end

        c << n(:id => 321, :name => 'Opłaty') do |c|
          c << n(:id => 32101, :name => 'Telewizja')
          c << n(:id => 32102, :name => 'Internet')
          c << n(:id => 32103, :name => 'Czynsz')
          c << n(:id => 32104, :name => 'Woda')
          c << n(:id => 32105, :name => 'Prąd')
          c << n(:id => 32106, :name => 'Gaz')
          c << n(:id => 32107, :name => 'Ogrzewanie')

          c << n(:id => 32108, :name => 'Telefon') do |c|
            c << n(:id => 3210801, :name => 'Abonament')
            c << n(:id => 3210802, :name => 'Doładowania')
          end
          
          c << n(:id => 32109, :name => 'Alimenty')
        end

        c << n(:id => 322, :name => 'Grzywny')

        c << n(:id => 323, :name => 'Ubezpieczenie') do |c|
          c << n(:id => 32301, :name => 'Zdrowotne')
          c << n(:id => 32302, :name => 'Na życie')
          c << n(:id => 32303, :name => 'Samochód')
          c << n(:id => 32304, :name => 'Mieszkanie')
          c << n(:id => 32305, :name => 'Podróżne')
          c << n(:id => 32306, :name => 'Odpowiedzialnośc cywilna')
          c << n(:id => 32307, :name => 'NNW')
        end

        c << n(:id => 324, :name => 'Podatki')

        c << n(:id => 325, :name => 'Konkursy i loterie')

        c << n(:id => 326, :name => 'Usługi')

        c << n(:id => 327, :name => 'Składki członkowskie')

        c << n(:id => 328, :name => 'Używki') do |c|
          c << n(:id => 32801, :name => 'Papierosy')
          c << n(:id => 32802, :name => 'Alkohol')
        end

        c << n(:id => 329, :name => 'Zagubione')
        c << n(:id => 330, :name => 'Umorzone długi')
      end
    end

    def create_loan
      n(:id => 4, :name => 'Zobowiązania', :category_type => :LOAN) do |c|
        c << n(:id => 401, :name => 'Karta kredytowa')
        c << n(:id => 402, :name => 'Urząd Skarbowy')
        c << n(:id => 403, :name => 'Rodzina')
        c << n(:id => 404, :name => 'Przyjaciele')
        c << n(:id => 405, :name => 'Znajomi')
      end
    end

    #  def create_balance
    #    n(:id => 500, :name => 'Bilanse otwarcia', :category_type => :BALANCE)
    #  end

  end

end