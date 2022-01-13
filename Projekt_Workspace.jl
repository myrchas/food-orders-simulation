using Pkg
using CSV
using DataFrames
using Distributions
using Random
using StatsBase

Pkg.installed()

##Zmienne
#Menu z cenami

#menu = Dict("BigMac"=>20, "Drwal"=>30, "McNuggets"=>23, "McChicken" => 25, "Wege" => 18)
prices = [20, 30, 23, 25, 18]
#Produkty i ich data waznosci
#val = Dict("BigMac"=>20, "Drwal"=>20, "McNuggets"=>15, "McChicken" => 25, "Wege" => 15)
val = [20, 20, 15, 25, 15]
#Początkowy stan produktów
#start = Dict("BigMac"=>20, "Drwal"=>20, "McNuggets"=>20, "McChicken" => 20, "Wege" => 20)
start = [20, 20, 20, 20, 20]
unfulfilled = zeros(5)




##Rozkłady 
#Ilość samochodów na minutę tworzymy rozkład zeby uzyc sample w funkcji
cars = [1, 2, 3, 4, 5]
prob = [0.15, 0.25, 0.2, 0.2, 0.1]
w = Weights(prob)

##Główna funkcja kroku
#jeden krok = jedna minuta

# function OneStep()
#     #wylosować z rozkładu samochdów na minutę ile samochdów przyjedzie w tym kroku
#     cars_num = sample(cars, w)
#     #wylosować ilość osób w kazdym samochodzie, 1 samochod = jedna zmienna?
#     num_ppl = Dict(i => rand(1:cars_num) for i in 1:cars_num)
#     # wylosować zamówienia dla kazdego samochodu, zapisujemy je jako data DataFrame
#     #gdzie kolumny to produkty zamowione a rzedy to nr samochodu
#     orders = DataFrame(BigMac = zeros(cars_num), Drwal = zeros(cars_num),
#     McNuggets = zeros(cars_num), McChicken = zeros(cars_num), Wege = zeros(cars_num))
    
#     #losujemy zamowienia dla kazdego samochodu
#     for i in 1:nrow(orders)
#         for j in 1:length(num_ppl)
#             prod = rand(1:ncol(orders))
#             orders[i, prod] += 1
#         end
#     end
    
    
    


cars_num = sample(cars, w)
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

sum_order = sum.(eachcol(orders))
start -= sum_order
end_inv = start

for i in 1:length(end_inv)
    if(end_inv[i] < 0)
        unfulfilled[i] += end_inv[i]
        end_inv[i] = 0
    end
end

fulfilled = sum_order - unfulfilled

gain = fulfilled .* prices
penalty = unfulfilled .* (0.25*prices)
val .-= 1
for i in 1:lenght(val)
    if(val[i] <= 0)
        thrown_out[i] = end_inv[i]



        
    
    




