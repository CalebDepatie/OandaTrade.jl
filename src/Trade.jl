module Trade

using JSON3, HTTP, Dates

"Detailed Trade struct from Oanda"
mutable struct trade
    averageClosePrice # The average closing price of the Trade
    clientExtensions # The client extensions of the Trade
    closingTransactionIDs # The IDs of the Transactions that have closed portions of this Trade
    closeTime # The date/time when the Trade was fully closed
    currentUnits # Current units of the trade (- is short + is long)
    dividend # The dividend paid for this Trade
    financing # The financing paid / collected for this trade
    id # The id of the trade
    initialUnits # Initial opening units of the trade (- is short + is long)
    initialMarginRequired # The margin required at the time the Trade was created
    instrument # Instrument of the trade
    marginUsed # Margin currently used by the Trade
    openTime # The time the trade was opened
    price # The price the trade is set at
    realizedPL # The profit / loss of the trade that has been incurred
    state # current state of the trade
    takeProfitOrder # Full representation of the Trade’s Take Profit Order
    stopLossOrder # Full representation of the Trade’s Stop Loss Order
    trailingStopLossOrder # Full representation of the Trade’s Trailing Stop Loss Order
    unrealizedPL # The profit / loss of the trade that hasnt been incurred
    #= Better implementation that requires complete implementation of Order.jl
    takeProfitOrder::takeProfitOrder
    stopLossOrder::stopLossOrder
    trailingStopLossOrder::trailingStopLossOrder
    =#
    trade() = new()
end


"Coerce a given 'trade' into its proper types (Used internally)"
function coerceTrade(trade::trade)
    
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    isdefined(trade,:averageClosePrice) && (trade.averageClosePrice = parse(Float32,trade.averageClosePrice))
    isdefined(trade,:closeTime) && (trade.closeTime = DateTime(first(trade.closeTime,23),RFC))
    trade.currentUnits = parse(Float32, trade.currentUnits)
    trade.initialUnits = parse(Float32, trade.initialUnits)
    trade.initialMarginRequired = parse(Float32,trade.initialMarginRequired)
    trade.financing = parse(Float32, trade.financing)
    # ID is left as a string, makes more sense to me for usage
    isdefined(trade,:marginUsed) && (trade.marginUsed = parse(Float32, marginUsed))
    trade.openTime = DateTime(first(trade.openTime,23),RFC)
    trade.price = parse(Float32, trade.price)
    trade.realizedPL = parse(Float32, trade.realizedPL)
    isdefined(trade,:unrealizedPL) && (trade.unrealizedPL = parse(Float32, trade.unrealizedPL))
    #= Requires complete implementation of Order.jl
    isdefined(trade,:takeProfitOrder) && (trade.takeProfitOrder = coerceTakeProfitOrder(trade.takeProfitOrder))
    isdefined(trade,:stopLossOrder) && (trade.stopLossOrder = coerceStopLossOrder(trade.stopLossOrder))
    isdefined(trade,:trailingStopLossOrder) && (trade.trailingStopLossOrder = coerceTrailingStopLossOrder(trade.trailingStopLossOrder))
    =#
    return trade
end

mutable struct trades
    trades::Vector{trade}
    lastTransactionID

    trades() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{trades}) = JSON3.Mutable()
JSON3.StructType(::Type{trade}) = JSON3.Mutable()

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/trades Endpoint
# ------------------------------------------------------------------------------------
"""
    getTrades(config::config, instrument::String, state::String="OPEN", count::Int=50; kwargs...)

    Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'state::String": the state to filter the requested Trades by (OPEN, CLOSED, CLOSE_WHEN_TRADEABLE, ALL)
- 'count::Int': max number of trades to return

# Keyword Arguments
- 'instrument::String": a valid instrument (e.g. "EUR_USD")
- 'ids::String' List of trades to retrieve as ID values separated by commas
- 'beforeID::String' The maximum trade ID to return

# Examples

    getTrades(userdata,"CLOSED";instrument="EUR_USD")

"""
function getTrades(config::config, state::String="ALL", count::Int=50; kwargs...)
   
    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/trades"),
        ["Authorization" => string("Bearer ", config.token)];
        query = push!(Dict(), "state" => state, "count" => count, kwargs...))

    temp = JSON3.read(r.body,trades)
    #type coersions
    for t in temp.trades
        t = coerceTrade(t)
     end
    
    temp.trades #Not returning lastTransactionID. That info belongs to Transaction.jl
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/openTrades Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/trades/{tradeSpecifier} Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/close Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/clientExtensions Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/orders Endpoint
# ------------------------------------------------------------------------------------

end #Module