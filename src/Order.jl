module Order
using JSON3, HTTP, Dates

export extensions, clientExtensions, takeProfit, stopLoss, trailingStopLoss # Structs also used in Trade.jl
#TODO: export user functions

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

"Detailed Order struct from Oanda"
mutable struct orderRequest
    clientExtensions::clientExtensions 
    gtdTime
    instrument # instrument of the order
    positionFill # Type of position fill on the order
    price # Price the order is placed at
    priceBound 
    stopLossOnFill::stopLoss # Stop loss settings for an order
    takeProfitOnFill::takeProfit
    timeInForce # Type of time in force
    tradeClientExtensions::clientExtensions
    trailingStopLossOnFill::trailingStopLoss
    triggerCondition # Trigger condition of the order
    type # Type of order
    units # Number of units (negative for a short, positive for a long)

    orderRequest() = new()
end


"For JSON parsing"
struct order
    order::orderRequest
end

"Coerce a given Order into its proper types (Used internally)"
function coerceOrder(order::order)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")
    order.createTime = DateTime(first(order.createTime, 23), RFC)
    order.price = parse(Float32, order.price)
    order.units = parse(Int32, order.units)
    order.stopLossOnFill.price = parse(Float32, order.stopLossOnFill.price)
    return order
end

# Declaring JSON3 struct types



JSON3.StructType(::Type{takeProfit}) = JSON3.Mutable()
JSON3.omitempties(::Type{takeProfit})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{stopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{stopLoss})=(:price,:distance,:timeInForce,:gtdTime)

JSON3.StructType(::Type{trailingStopLoss}) = JSON3.Mutable()
JSON3.omitempties(::Type{trailingStopLoss})=(:price,:timeInForce,:gtdTime)

JSON3.StructType(::Type{orderRequest}) = JSON3.Mutable()
JSON3.omitempties(::Type{orderRequest})=(:price, :units, :priceBound,:triggerCondition,
                                        :takeProfit,:stopLoss,:trailingStopLoss,
                                         :clientExtensions,:tradeClientExtensions)

JSON3.StructType(::Type{order}) = JSON3.Struct()


"""
function marketOrder(config, instrument, units;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt)

"""
function marketOrder(config::config, instrument::String, units::Real;
                     TIF::String = "FOK", positionFill::String = "DEFAULT", priceBound::Union{Nothing,String}=nothing,
                     TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                     clientExt::::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())
  
    order = orderRequest()
    
    order.type = "MARKET"
    order.instrument = instrument
    order.units = units
    order.timeInForce = TIF
    order.positionFill = positionFill
    order.priceBound = priceBound

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        order.takeProfit = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        order.stopLoss = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        order.trailingStopLoss = tSLdetails
    end

    # TODO: Client Extensions

    data = orderRequest(order)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
        ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
        JSON3.write(data),)

    return true
end




mutable struct tradeOrderRequest
    clientExtensions::clientExtensions 
    clientTradeID
    distance # Distance in Units for setting a SL or tSL order
    gtdTime
    price # Price the order is placed at
    timeInForce # Type of time in force
    tradeID
    triggerCondition # Trigger condition of the order
    type # Type of order

    tradeOrderRequest() = new()
end


"""

setTradeOrder


Also see setTradeOrders in Trade.jl for setting multiple orders at once

"""

end
