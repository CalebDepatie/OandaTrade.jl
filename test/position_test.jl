using Test, Julianda

foo = Julianda.Config.loadConfig("../config")

bar = Julianda.Position.listPositions(foo)
@test length(bar) != 0
