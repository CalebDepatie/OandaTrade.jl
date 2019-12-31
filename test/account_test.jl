using Test

using Julianda

foo = Julianda.Config.loadConfig("../config")

@test length(Julianda.Account.listAccounts(foo)) != 0

bar = Julianda.Account.listAccounts(foo)
foo2 = Julianda.Config.changeAccount(foo, bar[1].id)
@test foo2 == foo
@test Julianda.Config.saveConfig("../config_test", foo)

@test typeof(Julianda.Account.getAccount(foo)) == Julianda.Account.account
@test typeof(Julianda.Account.getAccountSummary(foo)) == Julianda.Account.account
@test length(Julianda.Account.getAccountInstruments(foo)) != 0
@test Julianda.Account.setAccountConfig(foo, "Testing", "0.05")
