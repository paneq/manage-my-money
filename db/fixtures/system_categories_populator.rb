#Info: 153 system categories total
class SystemCategoriesPopulator < DataPopulator
  class << self

    def load_data
      create_asset
      create_expense
      create_income
      create_loan
    end

    def cache_data
      SystemCategory.all.each do |sc|
        sc.cached_level = sc.level
        sc.name_with_path = sc.get_name_with_path
        sc.save!
      end
    end


    protected

    def create_asset
      n(:id => 1, :name => 'Zasoby', :category_type => :ASSET) do |c1|
        c1 << n(:id => 101, :name => 'Fundusze') do |c2|
          c2 << n(:id => 10101, :name => 'Fundusze zrównoważone')
          c2 << n(:id => 10102, :name => 'Fundusze obligacji')
          c2 << n(:id => 10103, :name => 'Fundusze akcji')
          c2 << n(:id => 10104, :name => 'Fundusze stabilnego wzrostu')
          c2 << n(:id => 10105, :name => 'Fundusze pieniężne')
          c2 << n(:id => 10106, :name => 'Fundusze zagraniczne')
        end

        c1 << n(:id => 102, :name => 'Konta bankowe') do |c2|
          c2 << n(:id => 10201, :name => 'Rachunki bieżące')
          c2 << n(:id => 10202, :name => 'Konta oszczędnościowe')
        end

        c1 << n(:id => 103, :name => 'Gotówka') do |c2|
          c2 << n(:id => 10301, :name => 'Portfel')
          c2 << n(:id => 10302, :name => "'Skarpeta'")
        end

        c1 << n(:id => 104, :name => 'Konta wirtualne') do |c2|
          c2 << n(:id => 10401, :name => 'Paypal')
        end

        c1 << n(:id => 105, :name => 'Lokaty')

      end
    end

    def create_income
      n(:id => 2, :name => 'Przychody', :category_type => :INCOME) do |c1|
        c1 << n(:id => 201, :name => 'Zyski z inwestycji')
        c1 << n(:id => 202, :name => 'Wynagrodzenie')
        c1 << n(:id => 203, :name => 'Premia')
        c1 << n(:id => 204, :name => 'Darowizny i spadki')
        c1 << n(:id => 205, :name => 'Wygrane')
        c1 << n(:id => 206, :name => 'Otrzymane prezenty')
      end
    end


    def create_expense
      n(:id => 3,  :name => 'Wydatki', :category_type => :EXPENSE) do |c1|
        c1 << n(:id => 301, :name => 'Opłaty bankowe')

        c1 << n(:id => 302, :name => 'Samochód') do  |c2|
          c2 << n(:id => 30201, :name => 'Naprawy i części')
          c2 << n(:id => 30202, :name => 'Kosmetyka')
          c2 << n(:id => 30203, :name => 'Opłaty stałe')
          c2 << n(:id => 30204, :name => 'Wyposażenie')
          c2 << n(:id => 30205, :name => 'Paliwo')
          c2 << n(:id => 30206, :name => 'Parking')
        end

        c1 << n(:id => 303, :name => 'Dobroczynność')

        c1 << n(:id => 304, :name => 'Ubrania') do |c2|
          c2 << n(:id => 30401, :name => 'Czyszczenie')
          c2 << n(:id => 30402, :name => 'Naprawa')
          c2 << n(:id => 30403, :name => 'Konserwacja')
        end

        c1 << n(:id => 305, :name => 'Kultura i rozrywka') do |c2|
          c2 << n(:id => 30501, :name => 'Koncerty')
          c2 << n(:id => 30502, :name => 'Kino')
          c2 << n(:id => 30503, :name => 'Teatr i opera')
          c2 << n(:id => 30504, :name => 'Sport')
          c2 << n(:id => 30505, :name => 'Wypoczynek')
          c2 << n(:id => 30506, :name => 'Podróże i noclegi')
          c2 << n(:id => 30507, :name => 'Imprezy i wydarzenia')
          c2 << n(:id => 30508, :name => 'Gry')
          c2 << n(:id => 30509, :name => 'Książki')
          c2 << n(:id => 30510, :name => 'Prasa')
          c2 << n(:id => 30511, :name => 'Muzyka')
        end

        c1 << n(:id => 306, :name => 'Podarunki')

        c1 << n(:id => 307, :name => 'Jedzenie') do |c2|
          c2 << n(:id => 30701, :name => 'Art. spożywcze') do |c3|
            c3 << n(:id => 3070101, :name => 'Owoce')
            c3 << n(:id => 3070102, :name => 'Warzywa')
            c3 << n(:id => 3070103, :name => 'Mięso')
            c3 << n(:id => 3070104, :name => 'Nabiał') do |c4|
              c4 << n(:id => 307010401, :name => 'Sery')
              c4 << n(:id => 307010402, :name => 'Mleko')
              c4 << n(:id => 307010403, :name => 'Jogurty')
            end
            c3 << n(:id => 3070105, :name => 'Napoje') do |c4|
              c4 << n(:id => 307010501, :name => 'Woda')
              c4 << n(:id => 307010502, :name => 'Gazowane')
              c4 << n(:id => 307010503, :name => 'Soki')
              c4 << n(:id => 307010504, :name => 'Kawa i herbata')
              c4 << n(:id => 307010505, :name => 'Alkohol') do |c5|
                c5 << n(:id => 307010506, :name => 'Piwo')
                c5 << n(:id => 307010507, :name => 'Wino')
                c5 << n(:id => 307010508, :name => 'Wódka')
                c5 << n(:id => 307010509, :name => 'Whisky')
              end
            end
          end
          c2 << n(:id => 30702, :name => 'Słodycze i przekąski')
          c2 << n(:id => 308, :name => 'Fast food')
          c2 << n(:id => 309, :name => 'Bary mleczne')
          c2 << n(:id => 310, :name => 'Bary wegetariańskie')
          c2 << n(:id => 311, :name => 'Restauracja, kawiarnia, pub')
        end
        

        c1 << n(:id => 312, :name => 'Transport') do |c2|
          c2 << n(:id => 31201, :name => 'Przejazdy pociągiem')
          c2 << n(:id => 31202, :name => 'Przeloty')
          c2 << n(:id => 31203, :name => 'Komunikacja wodna')
          c2 << n(:id => 31204, :name => 'Komunikacja autobusowa')
          c2 << n(:id => 31205, :name => 'Komunikacja miejska')
          c2 << n(:id => 31206, :name => 'Taxi')
          c2 << n(:id => 31207, :name => 'Samochód') do |c3|
            c3 << n(:id => 3120701, :name => 'Paliwo')
            c3 << n(:id => 3120702, :name => 'Parking')
          end
        end


        c1 << n(:id => 313, :name => 'Komputer') do |c2|
          c2 << n(:id => 31301, :name => 'Części')
          c2 << n(:id => 31302, :name => 'Akcesoria')
          c2 << n(:id => 31303, :name => 'Oprogramowanie')
          c2 << n(:id => 31304, :name => 'Gry')
          c2 << n(:id => 31305, :name => 'Naprawy')
        end

        c1 << n(:id => 314, :name => 'Edukacja') do |c2|
          c2 << n(:id => 31401, :name => 'Czesne')
          c2 << n(:id => 31402, :name => 'Materiały naukowe')
        end

        c1 << n(:id => 315, :name => 'Zdrowie') do |c2|
          c2 << n(:id => 31501, :name => 'Leki')
          c2 << n(:id => 31502, :name => 'Profilaktyka')
          c2 << n(:id => 31503, :name => 'Lekarz')
        end

        c1 << n(:id => 316, :name => 'Hobby')
      
        c1 << n(:id => 317, :name => 'Usługi online') do |c2|
          c2 << n(:id => 31701, :name => 'Hosting')
          c2 << n(:id => 31702, :name => 'Domeny')
        end

        c1 << n(:id => 318, :name => 'Higiena osobista')
      
        c1 << n(:id => 319, :name => 'Elektronika') do |c2|
          c2 << n(:id => 31901, :name => 'AGD')
          c2 << n(:id => 31902, :name => 'RTV')
        end

        c1 << n(:id => 320, :name => 'Dom i ogród') do |c2|
          c2 << n(:id => 32001, :name => 'Środki czystości')
          c2 << n(:id => 32002, :name => 'AGD')
          c2 << n(:id => 32003, :name => 'RTV')
          c2 << n(:id => 32004, :name => 'Meble')
          c2 << n(:id => 32005, :name => 'Akcesoria')
          c2 << n(:id => 32006, :name => 'Ogród')
          c2 << n(:id => 32007, :name => 'Czynsz')
          c2 << n(:id => 32008, :name => 'Woda')
          c2 << n(:id => 32009, :name => 'Prąd')
          c2 << n(:id => 32010, :name => 'Gaz')
        end

        c1 << n(:id => 321, :name => 'Opłaty') do |c2|
          c2 << n(:id => 32101, :name => 'Telewizja')
          c2 << n(:id => 32102, :name => 'Internet')
          c2 << n(:id => 32103, :name => 'Czynsz')
          c2 << n(:id => 32104, :name => 'Woda')
          c2 << n(:id => 32105, :name => 'Prąd')
          c2 << n(:id => 32106, :name => 'Gaz')
          c2 << n(:id => 32107, :name => 'Ogrzewanie')

          c2 << n(:id => 32108, :name => 'Telefon') do |c3|
            c3 << n(:id => 3210801, :name => 'Abonament')
            c3 << n(:id => 3210802, :name => 'Doładowania')
          end
          
          c2 << n(:id => 32109, :name => 'Alimenty')
        end

        c1 << n(:id => 322, :name => 'Grzywny')

        c1 << n(:id => 323, :name => 'Ubezpieczenie') do |c2|
          c2 << n(:id => 32301, :name => 'Zdrowotne')
          c2 << n(:id => 32302, :name => 'Na życie')
          c2 << n(:id => 32303, :name => 'Samochód')
          c2 << n(:id => 32304, :name => 'Mieszkanie')
          c2 << n(:id => 32305, :name => 'Podróżne')
          c2 << n(:id => 32306, :name => 'Odpowiedzialnośc cywilna')
          c2 << n(:id => 32307, :name => 'NNW')
        end

        c1 << n(:id => 324, :name => 'Podatki')

        c1 << n(:id => 325, :name => 'Konkursy i loterie')

        c1 << n(:id => 326, :name => 'Usługi')

        c1 << n(:id => 327, :name => 'Składki członkowskie')

        c1 << n(:id => 328, :name => 'Używki') do |c2|
          c2 << n(:id => 32801, :name => 'Papierosy')
          c2 << n(:id => 32802, :name => 'Alkohol')
        end

        c1 << n(:id => 329, :name => 'Zagubione')
        c1 << n(:id => 330, :name => 'Umorzone długi')
      end
    end

    def create_loan
      n(:id => 4, :name => 'Zobowiązania', :category_type => :LOAN) do |c1|
        c1 << n(:id => 401, :name => 'Karta kredytowa')
        c1 << n(:id => 402, :name => 'Urząd Skarbowy')
        c1 << n(:id => 403, :name => 'Rodzina')
        c1 << n(:id => 404, :name => 'Przyjaciele')
        c1 << n(:id => 405, :name => 'Znajomi')
      end
    end


   

  end

end