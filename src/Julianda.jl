#__precompile__()

module Julianda

# TODO: Expand the structs with full JSON info (Can be found on the definitions page of oanda)

include("Order.jl")
include("Position.jl")
include("Trade.jl")
include("Account.jl")
include("Config.jl")
include("Instrument.jl")
include("Transaction.jl")
include("Pricing.jl")

end
