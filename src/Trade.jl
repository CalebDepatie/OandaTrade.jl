module Trade
using JSON3, Dates

"Detailed Trade struct from Oanda"
mutable struct trade
    currentUnits # Current units of the trade (- is short + is long)
    financing # The financing paid / collected for this trade
    id # The id of the trade
    initialUnits # Initial opening units of the trade (- is short + is long)
    instrument # Instrument of the trade
    openTime # The time the trade was opened
    price # The price the trade is set at
    realizedPL # The profit / loss of the trade that has been incurred
    state # current state of the trade
    unrealizedPL # The profit / loss of the trade that hasnt been incurred

    trade() = new()
end

"Coerce a given Trade into its proper types (Used internally)"
function coerceTrade(trade::trade)
    trade.currentUnits = parse(Int32, trade.currentUnits)
    trade.financing = parse(Float32, trade.financing)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")
    trade.openTime = DateTime(first(trade.openTime,23), RFC)
    trade.initialUnits = parse(Int32, trade.initialUnits)
    trade.price = parse(Float32, trade.price)
    trade.realizedPL = parse(Float32, trade.realizedPL)
    trade.unrealizedPL = parse(Float32, trade.unrealizedPL)
    return trade
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{Trade.trade}) = JSON3.Mutable()

end
