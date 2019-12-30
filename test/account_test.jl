using Test

using Julianda

foo = Julianda.Config.loadConfig("../config")

@test length(Julianda.Account.listAccounts(foo)) != 0
@test typeof(Julianda.Account.getAccount(foo)) == Julianda.Account.account
@test typeof(Julianda.Account.getAccountSummary(foo)) == Julianda.Account.account
@test length(Julianda.Account.getAccountInstruments(foo)) != 0
@test Julianda.Account.setAccountConfig(foo, "Testing", "0.05")
