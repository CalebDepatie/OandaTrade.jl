using Test, Julianda

foo = Julianda.Config.loadConfig("../config")

@test Julianda.Order.placeOrder(foo, "GBP_USD", 100)
