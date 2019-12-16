include("../src/Julianda.jl")

foo = Julianda.Config.loadConfig("config")

Julianda.Account.setAccountConfig(foo, "Testing", 0.05")

bar = Julianda.Account.getAccount(foo)
println(bar)
