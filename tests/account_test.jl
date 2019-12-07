include("../src/Julianda.jl")

foo = Julianda.Config.loadConfig("config")

bar = Julianda.Account.getAccount(foo)
println(bar)
