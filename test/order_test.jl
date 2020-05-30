using Test, Julianda

foo = Julianda.Config.loadConfig("../config")

#FIXME this test literally can't fail as its based on return type
bar = Julianda.Order.marketOrder(foo, "GBP_USD", 100)
@test typeof(bar) == Dict{String,Any}
