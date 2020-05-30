using Test, Julianda

foo = Julianda.Config.loadConfig("../config")

bar = Julianda.Position.listPositions(foo)
@test length(bar) != 0

bar = Julianda.Position.listOpenPositions(foo)
@test bar != nothing

bar = Julianda.Position.getPosition(foo, "GBP_USD")
@test bar.instrument == "GBP_USD"

#@test Julianda.Position.closePosition(foo, "GBP_USD", 50)

#@test Julianda.Position.closePositionFull(foo, "GBP_USD")
