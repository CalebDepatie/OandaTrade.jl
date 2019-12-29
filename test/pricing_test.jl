using Test

using Julianda

foo = Julianda.Config.loadConfig("../config")

# Keeps asking for price even if the market is closed
#@test Julianda.Pricing.getPrice(foo, "GBP_USD")
