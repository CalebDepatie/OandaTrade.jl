module Trade

using JSON3, HTTP, Dates

export getTrades, getOpenTrades, getTrade, closeTrade, clientExtensions, setTradeOrders, cancelTradeOrders

"Detailed Trade struct from Oanda"
mutable struct trade
    averageClosePrice # The average closing price of the Trad
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
    #= Better alternative that requires complete implementation of Order.jl
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
    isdefined(trade,:marginUsed) && (trade.marginUsed = parse(Float32, trade.marginUsed))
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
# /accounts/{accountID}/openTrades Endpoint
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

    getTrades(userConfig,"CLOSED";instrument="EUR_USD")

"""
function getTrades(config, state::String="ALL", count::Int=50; kwargs...)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/trades"),
        ["Authorization" => string("Bearer ", config.token)];
        query = push!(Dict(), "state" => state, "count" => count, kwargs...))

    temp = JSON3.read(r.body,trades)
    # type coersions
    for t in temp.trades
        t = coerceTrade(t)
    end
    temp.trades # Not returning lastTransactionID. That info belongs to Transaction.jl
end

"""
    getOpenTrades(config::config)

Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data

# Examples

    getOpenTrades(userconfig)

"""
function getOpenTrades(config)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/openTrades"),
        ["Authorization" => string("Bearer ", config.token)])

    temp = JSON3.read(r.body,trades)

    # type coersions
    for t in temp.trades
        t = coerceTrade(t)
    end
    return temp.trades # Not returning lastTransactionID. That info belongs to Transaction.jl
end

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/trades/{tradeSpecifier} Endpoint
# ------------------------------------------------------------------------------------
mutable struct singleTrade
    trade::trade
    lastTransactionID

    singleTrade() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{singleTrade}) = JSON3.Mutable()

"""
   getTrade(config::config, tradeID::String)

Return a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'id::string': a valid trade ID

# Examples

    getTrades(userconfig,"66")

"""
function getTrade(config, tradeID::String)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID),
        ["Authorization" => string("Bearer ", config.token)])

    temp = JSON3.read(r.body,singleTrade)

    return coerceTrade(temp.trade) # Not returning lastTransactionID. That info belongs to Transaction.jl
end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/close Endpoint
# ------------------------------------------------------------------------------------

# close trade endpoint response struct
mutable struct closeUnitsResp
    orderCreateTransaction::Dict{String,Any}
    orderFillTransaction::Dict{String,Any}
    orderCancelTransaction::Dict{String,Any}
    relatedTransactionIDs::Vector{String}
    lastTransactionID

    closeUnitsResp() = new()
end

# close trade endpoint request struct
struct closeUnits
    units::String

    closeUnits(x::String) = new(x)

    function closeUnits(x::Real)
        str = string(x)
        new(str)
    end

end

# Declaring JSON3 struct types
JSON3.StructType(::Type{closeUnits}) = JSON3.Struct()
JSON3.StructType(::Type{closeUnitsResp}) = JSON3.Mutable()

"""
    closeTrade(config::config, tradeID::String, units::Union{Real,String}="ALL")

Return an array of trade struct

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- 'units::Union{Number,String}': how much of the Trade to close in units or "ALL"

# Examples

    closeTrade(userconfig,"66","ALL")

"""
function closeTrade(config, tradeID::String, units::Union{Real,String}="ALL")

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/close"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(closeUnits(units)))

    return JSON3.read(r.body,closeUnitsResp)

end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/clientExtensions Endpoint
# ------------------------------------------------------------------------------------

# clientExtensions response struct
mutable struct clientExtensionsResp
    tradeClientExtensionsModifyTransaction::Dict{String,Any}
    relatedTransactionIDs::Vector{String}
    lastTransactionID

    clientExtensionsResp() = new()
end

# clientExtension request structs
struct extensions
    id::String
    tag::String
    comment::String
end

# For JSON parsing
struct clientExtensions
    clientExtensions::extensions
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{clientExtensions}) = JSON3.Struct()
JSON3.StructType(::Type{extensions}) = JSON3.Struct()
JSON3.StructType(::Type{clientExtensionsResp}) = JSON3.Mutable()

"""
    clientExtensions(config::config, tradeID::String; clientID::String="", tag::String="", comment::String="")

Lets add user information to a specific Trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- clientID, tag and comment: strings with the user information

# Example

    clientExtensions(userconfig,"66", clientID="007",tag="foo")

"""
function clientExtensions(config, tradeID::String; clientID::String="", tag::String="", comment::String="")

    data = clientExtensions(extensions(clientID, tag, comment))

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/clientExtensions"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body, clientExtensionsResp)

end

# ------------------------------------------------------------------------------------
# //accounts/{accountID}/trades/{tradeSpecifier}/orders Endpoint
# ------------------------------------------------------------------------------------

# orders endpoint response struct
mutable struct tradeOrdersResponse
    takeProfitOrderCancelTransaction::Dict{String,Any}
    takeProfitOrderTransaction::Dict{String,Any}
    takeProfitOrderFillTransaction::Dict{String,Any}
    takeProfitOrderCreatedCancelTransaction::Dict{String,Any}
    stopLossOrderCancelTransaction::Dict{String,Any}
    stopLossOrderTransaction::Dict{String,Any}
    stopLossOrderCreatedCancelTransaction::Dict{String,Any}
    trailingStopLossOrderCancelTransaction::Dict{String,Any}
    trailingStopLossOrderTransaction::Dict{String,Any}
    relatedTransactionIDs::Vector{String}
    lastTransactionID

    tradeOrdersResponse() = new()
end

# orders endpoint request structs
mutable struct takeProfit
    price::Real
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO
    takeProfit() = new()
end

mutable struct stopLoss
    price::Real
    distance::Real
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO

    stopLoss() = new()
end

mutable struct trailingStopLoss
    distance::Real
    timeInForce::String
    gtdTime::String
    # clientExtensions::extensions -> TODO

    trailingStopLoss() = new()
end

mutable struct tradeOrders
    takeProfit::takeProfit
    stopLoss::stopLoss
    trailingStopLoss::trailingStopLoss

    tradeOrders()=new()
end

# Declaring JSON3 struct types and setting fields to ignore in JSON3.write if # undef
JSON3.StructType(::Type{tradeOrders}) = JSON3.Mutable()
JSON3.omitempties(::Type{tradeOrders})=(:takeProfit,:stopLoss,:trailingStopLoss)

JSON3.StructType(::Type{takeProfit}) = JSON3.Mutable()
JSON3.omitempties(::Type{takeProfit})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{stopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{stopLoss})=(:price,:distance,:timeInForce,:gtdTime)

JSON3.StructType(::Type{trailingStopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{trailingStopLoss})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{tradeOrdersResponse}) = JSON3.Mutable()

"""
    function setTradeOrders(config::config, tradeID::String; [TP::NamedTuple, SL::NamedTuple, tSL::NamedTuple ])

Create or modify the linked orders for a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID

# Additional Arguments
- 'TP::NamedTuple' Take Profit parameters
- 'SL::NamedTuple': Stop Loss parameters
- 'tSL::NamedTuple': Trailing Stop Loss parameters

At least one type of order parameters must be provided

# Valid order parameters
- 'price = :Real' :price to create o modify for the specific order. Valir for Stop Loss and Take Profit
- 'distance = :Real' :price distance to create o modify for the specific order. Valir for Stop Loss and Trailing Stip Loss
- 'TIF= String': time in force for the order. Valid options are: GTC, GTD, GFD, FOK, IOC. Defaults to GTC
- 'gtdTime = DateTime': time for GTD (Good unTill Date)

Price and distance are incompatible. Only one can be set for a given order.

# Example

    setTradeOrders(userconfig, "34"; TP=(price=109.5,), SL=(distance=10,TIF="FOK")) # Do not forget the comma for 1 element NamedTuples

"""
function setTradeOrders(config, tradeID::String; TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple())

    data = tradeOrders()

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.takeProfit = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.stopLoss = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        data.trailingStopLoss = tSLdetails
    end


    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/orders"),
        ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body,tradeOrdersResponse)

end

# Definition of cancelTradeOrders structs
mutable struct nullTradeOrders
    takeProfit
    stopLoss
    trailingStopLoss

    nullTradeOrders()=new()
end

# Declaring JSON3 struct types and setting fields to ignore in JSON3.write if # undef
JSON3.StructType(::Type{nullTradeOrders}) = JSON3.Mutable()
JSON3.omitempties(::Type{nullTradeOrders})=(:takeProfit,:stopLoss,:trailingStopLoss)

"""
    function cancelTradeOrders(config::config, tradeID::String, orders2cancel::Vector{String})

Cancel linked orders of a specific trade

# Arguments
- 'config::config': a valid struct with user configuracion data
- 'tradeID::string': a valid trade ID
- 'orders2cancel::Vector{String}': list of orders to cancel.

order2cancel valid fields are "TP" for Take Profit, "SL" for Stop Loss and "tSL" for Trailing Stop Loss

# Example

    cancelTradeOrders(userconfig, "34", ["SL", "TP"])

end
"""
function cancelTradeOrders(config, tradeID::String, orders2cancel::Vector{String})

    data=nullTradeOrders()

    in("TP",orders2cancel) && (data.takeProfit=missing)
    in("SL",orders2cancel) && (data.stopLoss=missing)
    in("tSL",orders2cancel) && (data.trailingStopLoss=missing)

    r = HTTP.put(string("https://", config.hostname, "/v3/accounts/", config.account,"/trades/",tradeID,"/orders"),
    ["Authorization" => string("Bearer ", config.token),"Content-Type" => "application/json"], JSON3.write(data))

    return JSON3.read(r.body,tradeOrdersResponse)
end

end # Module
