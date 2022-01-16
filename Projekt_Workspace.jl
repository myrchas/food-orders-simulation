using Pkg
using CSV
using DataFrames
using Distributions
using Random
using StatsBase
using NamedArrays
using Plots

score = [0.0, 0, 0, 0]
    

function OneStep(start_inv, start, num_cars, weights, start_val, val)
    cars_num = sample(num_cars, weights)
    #wylosować ilość osób w kazdym samochodzie, 1 samochod = jedna zmienna?
    num_ppl = Dict(i => rand(1:cars_num) for i in 1:cars_num)
    # wylosować zamówienia dla kazdego samochodu, zapisujemy je jako data DataFrame
    #gdzie kolumny to produkty zamowione a rzedy to nr samochodu
    orders = DataFrame(BigMac = zeros(cars_num), Drwal = zeros(cars_num),
    McNuggets = zeros(cars_num), McChicken = zeros(cars_num), Wege = zeros(cars_num))
        
    #losujemy zamowienia dla kazdego samochodu
    for i in 1:nrow(orders)
        for j in 1:length(num_ppl)
                prod = rand(1:ncol(orders))
                orders[i, prod] += 1
        end
    end
    
    #sumujemy zamówienia po kolumnach z wszystkich samochodów
    sum_order = sum.(eachcol(orders))
    #odejmujemy od inventory zamówione składniki
    end_inv = start - sum_order
    #vektor ile zamówień nie udalo sie wypelnic na razie 0
    unfulfilled = zeros(5)

    #jesli inventory zeszlo ponizej zera to tyle ile jest na minusie tyle zamowien nie uda sie spelnic
    for i in 1:length(end_inv)
        if(end_inv[i] < 0)
            unfulfilled[i] -= end_inv[i]
            end_inv[i] = 0
        end
    end
    #spelnione zamowienia to wszystkie zamowienia - niespelnione
    fulfilled = sum_order - unfulfilled
    #przychod
    gain = fulfilled .* prices
    #kara za niespelnienie zamowien
    penalty = unfulfilled .* (0.25*prices)
    #zmniejszamy o jedna minute waznosc produktow
    val .-= 1
    #to co musielismy wyrzucic na razie zera
    thrown_out = zeros(5)
    #jesli waznosc spadnie do 0 to musimy wyrzucic to co zostalo i zrobic nowe oraz zaktualizowac date wwaznosci
    for i in 1:length(val)
        if(val[i] <= 0)
            thrown_out[i] = end_inv[i]
            end_inv[i] += start_inv[i]
            val[i] = start_val[i]
        end
    end
    #strata policzona na podstawie wyrzuconych 
    #mozna zmienic te 0.25 i powiedziec ze co sie stanie jak produkty zdrozeja
    loss = thrown_out.* (0.25*prices)
    # zysk
    profit = gain - penalty - loss
    #wyniki
    score[1] = sum(profit) #zysk
    score[2] = sum(thrown_out)#ile wyrzucilismy w tej minucie
    score[3] = abs(sum(unfulfilled)) #ile zamowien zostalo niespelnionych w  tej minucie
    score[4] = sum(fulfilled) # ile zamowien spelnionych w tej minucie

    
    #nadpisujemy startowe inventory
    start = end_inv
    #zwracamy wynik koncowe inventory oraz obecna date waznosci do nastepnej iteracji
    return score, end_inv, val
end

#horizon to ilosc minut jaka chcemy miec w symulacji najlepiej 60
#val to daty waznosci
#start to inventory na poczatku minuty
#mean_val to ile razy odpalamy symulacje zeby policzyc srednie wartosci
function SimulateOneRun(horizon, val, start, mean_val)
    #Ceny produktów
    prices = [20, 30, 23, 25, 18]
    #pusty wektor do wynikow
    summed_out = zeros(4)
    #tutaj jest petla zeby wyciagac srednia z wynikow, poniewaz losujemy wiele rzeczy
    #chcemy zeby wyniki byly srednia z wielu przebiegow
    #mean_val to ilosc iteracji do liczenia sredniej (im wiecej tym lepiej)
    for i in 1:mean_val
        #obecne daty waznosci
        _val = val
        #stałe poczatkowe daty
        start_val = deepcopy(_val)
        score = [0.0, 0.0, 0.0, 0.0]
        #obecny stan inventory
        _start = start
        #staly poczatkowy stan inventory
        start_inventory = deepcopy(_start)
        #Ilość samochodów na minutę tworzymy rozkład zeby uzyc sample w funkcji
        cars = [1, 2, 3, 4, 5]
        prob = [0.15, 0.25, 0.2, 0.2, 0.1]
        w = Weights(prob)
        #Wynik symulacji jako dataframe
        df = DataFrame(Profit = 0.0, Thrown_out = 0.0, Unfulfilled = 0.0, Fulfilled = 0.0)
        #symulacja, horizon powinno byc 60 bo symulujemy godzine, mozna zwiekszac
        for i in 1:horizon
            #out to wyniki kroku, _start to stan inventory na koniec kroku/minuty,
            #_val to daty waznosci na koniec kroku/minuty
            out, _start, _val = OneStep(start_inventory, _start, cars, w, start_val, _val)
            #pushujemy do data frame
            push!(df, out[1:4])
        end
        #bierzemy wszystko od drugiego wyniku bo pierwszy to zera,
        #bo tworzylismy data frame z rzedem zer wczesniej
        df_out = df[2:end,:]
        #tutaj musimy skleic rzedami wyniki z kazdej z tych symulacji zeby potem policzyc srednia po rzedach
        summed_out = hcat(summed_out, sum.(eachcol(df_out)))
    end

    #println(start_val)
    #liczymy srednia po rzedach od drugiej do ostatniej kolumny, bo pierwsza to zera
    return mean(summed_out[:, 2:end], dims = 2)
end

#mean_val to ilosc razy jaka odpalimy simulateOneRun zeby policzyc srednia, tam wyzej bylo opisane
function SimulatemanyRuns(mean_val)
    #daty waznosci
    validity = [10, 10, 10, 10, 10]
    #data frame z wynikami
    temp = DataFrame(Profit = 0.0, Thrown_out = 0.0, Unfulfilled = 0.0, Fulfilled = 0.0)
    #przykladowe stany inventory od 1 sztuki do 40 sztuk
    x = [fill(i, 5) for i in 1:40]
    #petla dla kazdego stanu inventory
    for i in x
       push!(temp, SimulateOneRun(60, validity, i, mean_val))
    end
    return temp
end

#uruchomienie symulacji
@time xd = SimulatemanyRuns(100)[2:end, :]
#to wyswietla caly data frame bez ucinania rzedow
show(stdout, "text/plain", xd)
#sprawdzmy dla jakich wartosci jest najwiekszy profit
#wylaczamy kolumne profit
profit = xd[!, "Profit"]
#wykres slupkowy
Plots.bar([1:1:40;], profit, label = "Profit")
#splotujmy jeszcze raz od 10 do 30
profit_2 = profit[10:30]
Plots.bar([10:1:30;], profit_2) 
