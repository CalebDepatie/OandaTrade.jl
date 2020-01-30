using Dates

include("../src/Julianda.jl")

foo = Julianda.Config.loadConfig("config")

bar = Julianda.Pricing.getPrice(foo, "GBP_USD")
println(bar)
