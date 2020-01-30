include("../src/Julianda.jl")

foo = Julianda.Config.loadConfig("config")

Julianda.Order.placeOrder(foo, "GBP_USD", 100)
