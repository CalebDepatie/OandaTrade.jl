module Order
using JSON3, HTTP, Dates

export extensions, clientExtensions, takeProfit, stopLoss, trailingStopLoss # Structs also used in Trade.jl
#TODO: export user functions

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders POST Endpoint
# ------------------------------------------------------------------------------------

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
JSON3.omitempties(::Type{orderRequest})=(:price, :units, :priceBound,:triggerCondition,:gtdTime,
                                         :takeProfitOnFill,:stopLossOnFill,:trailingStopLossOnFill,
                                         :clientExtensions,:tradeClientExtensions)

JSON3.StructType(::Type{order}) = JSON3.Struct()


# market order -----------------------------------------------------------------------
"""
 marketOrder(config, instrument, units;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

#Examples

   marketOrder(userData,"EUR_JPY",100)

   marketOrder(userData,"EUR_CHF",100,SL=(distance=0.1,),TP=(price=1.12,),tSL=(distance=0.3,))

"""
function marketOrder(config::config, instrument::String, units::Real;
                     TIF::String = "FOK", positionFill::String = "DEFAULT", priceBound::Union{Nothing,String}=nothing,
                     TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                     clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())
  
    o = orderRequest()
    
    o.type = "MARKET"
    o.instrument = instrument
    o.units = units
    o.timeInForce = TIF
    o.positionFill = positionFill
    o.priceBound = priceBound

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.takeProfitOnFill = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.stopLossOnFill = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.trailingStopLossOnFill = tSLdetails
    end

    # TODO: Client Extensions

    data = order(o)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
        ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
        JSON3.write(data),)

    return JSON3.read(r.body)
end


# Other type of orders -----------------------------------------------------------------------
"""
 nonmarketOrder(config, type, instrument, units, price;[TIF, gtdTime, positionFill, trigge, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

 generic order function for limit, stop and marketIfTouchedOrders

"""

function nonMarketOrder(config::config, type::String, instrument::String, units::Real, price::Real;
    TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT",priceBound::Union{Nothing,String}=nothing,
    TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
    clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple())

    o = orderRequest()

    o.type = type
    o.instrument = instrument
    o.units = units
    o.price = price
    o.timeInForce = TIF
    o.priceBound = priceBound
    !isnothing(gtdTime) && (o.gtdTime = Dates.format(gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))
    o.positionFill = positionFill
    o.triggerCondition = trigger

    if !isempty(TP)
        TPdetails = takeProfit()
        haskey(TP, :price) && (TPdetails.price = TP.price)
        haskey(TP, :timeInForce) && (TPdetails.timeInForce = TP.timeInForce)
        haskey(TP, :gtdTime) && (TPdetails.price = Dates.format(TP.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.takeProfitOnFill = TPdetails
    end

    if !isempty(SL)
        SLdetails = stopLoss()
        haskey(SL, :price) && (SLdetails.price = SL.price)
        haskey(SL, :distance) && (SLdetails.distance = SL.distance)
        haskey(SL, :timeInForce) && (SLdetails.timeInForce = SL.timeInForce)
        haskey(SL, :gtdTime) && (SLdetails.price = Dates.format(SL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

o.stopLossOnFill = SLdetails
    end

    if !isempty(tSL)
        tSLdetails = trailingStopLoss()
        haskey(tSL, :distance) && (tSLdetails.distance = tSL.distance)
        haskey(tSL, :timeInForce) && (tSLdetails.timeInForce = tSL.timeInForce)
        haskey(tSL, :gtdTime) && (tSLdetails.price = Dates.format(tSL.gtdTime,"yyyy-mm-ddTHH:MM:SS.sss000000Z"))

        o.trailingStopLossOnFill = tSLdetails
    end

    # TODO: Client Extensions

    data = order(o)

    r = HTTP.post(string("https://",config.hostname,"/v3/accounts/",config.account,"/orders",),
    ["Authorization" => string("Bearer ", config.token), "Content-Type" => "application/json", ],
    JSON3.write(data),)

    return JSON3.read(r.body)
end

# limit order -----------------------------------------------------------------------
"""

 limitOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

#Examples

   limitOrder(userData,"EUR_uSD",100, 1.10)

   limitOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,))

"""
limitOrder(config::config, instrument::String, units::Real, price::Real;
                    TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT",
                    TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                    clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
        nonMarketOrder(config, "LIMIT", instrument, units, price; 
                   TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, 
                   TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)
    
 # stop order -----------------------------------------------------------------------
"""

stopOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

#Examples

  stopOrder(userData,"EUR_USD",100, 1.10)

  stopOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,))

"""
stopOrder(config::config, instrument::String, units::Real, price::Real;
                   TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT", priceBound::Union{Nothing,String}=nothing,
                   TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                   clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
       nonMarketOrder(config, "STOP", instrument, units, price; 
                  TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, priceBound = priceBound,
                  TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)


# market if touched order -----------------------------------------------------------------------
"""

marketIfTouchedOrder(config, instrument, units, price;[TIF, positionFill, priceBound, TP ,SL ,tSL, clientExt ,tradeExt])

#Examples

  marketifTouchedOrder(userData,"EUR_uSD",100, 1.10)

  marketifTouchedOrder(userData,"EUR_JPY",100,117,SL=(distance=1,),TP=(price=12,),tSL=(distance=3,))

"""
marketIfTouchedOrder(config::config, instrument::String, units::Real, price::Real;
                   TIF::String = "GTC", gtdTime::Union{Nothing,String}=nothing, positionFill::String = "DEFAULT", trigger::String="DEFAULT", priceBound::Union{Nothing,String}=nothing,
                   TP::NamedTuple=NamedTuple(),SL::NamedTuple=NamedTuple(),tSL::NamedTuple=NamedTuple(),
                   clientExt::NamedTuple=NamedTuple(),tradeExt::NamedTuple=NamedTuple()) = 
       nonMarketOrder(config, "MARKET_IF_TOUCHED", instrument, units, price; 
                  TIF=TIF, gtdTime=gtdTime, positionFill=positionFill, trigger=trigger, priceBound = priceBound,
                  TP=TP, SL=SL ,tSL=tSL, clientExt=clientExt, tradeExt=tradeExt)
                 

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders GET Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pendingOrders GET Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier} GET Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier} PUT Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier}/cancel PUT Endpoint
# ------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/orders/{orderSpecifier}/clientExtension PUT Endpoint
# ------------------------------------------------------------------------------------

end
