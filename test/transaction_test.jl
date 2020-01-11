using Test, Julianda

foo = Julianda.Config.loadConfig("../config")

bar = Julianda.Transaction.getTransactionPages(foo)
@test bar.pageSize == 100

bar = Julianda.Transaction.getTransaction(foo, 1)
@test bar.transaction["type"] == "CREATE"

bar = Julianda.Transaction.getTransactions(foo, 1, 1)
@test bar.transactions[1]["type"] == "CREATE"
bar = Julianda.Transaction.getTransactions(foo, 1)
@test bar.transactions[1]["type"] == "CLIENT_CONFIGURE"
