using Test

using Julianda

foo = Julianda.Config.loadConfig("../config")

@test Julianda.Account.setAccountConfig(foo, "Testing", "0.05")
