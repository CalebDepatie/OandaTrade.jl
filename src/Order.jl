module Order
using JSON3, HTTP

"Stop loss settings for an order"
mutable struct stopLossOnFill
    price # Price for stop loss
    timeInForce # Type of time in force

    stopLossOnFill() = new()
end

"Detailed Order struct from Oanda"
mutable struct order
    createTime # When the order was created
    id # Id of the order
    instrument # instrument of the order
    partialFill # Type of partial fill on the order
    positionFill # Type of position fill on the order
    price # Price the order is placed at
    state # Current state of the order (Filled, pending)
    stopLossOnFill::stopLossOnFill # Stop loss settings for an order
    timeInForce # Type of time in force
    triggerCondition # Trigger condition of the order
    type # Type of order
    units # Number of units (negative for a short, positive for a long)

    order() = new()
end

"A market order request struct"
struct marketOrderRequest
    type # Type of order request
    instrument # Instrument the order is for
    units # Number of units to order (Negative is a short order)
    timeInForce # Time in force requested
    priceBound # Worst price the order is allowed to be filled at
    positionFill # How the position fills

end

"For JSON parsing"
struct orderRequest
    order::marketOrderRequest
end

"Coerce a given Order into its proper types (Used internally)"
function coerceOrder(order::order)
    order.price = parse(Float32, order.price)
    order.units = parse(Int32, order.units)
    order.stopLossOnFill.price = parse(Float32, order.stopLossOnFill.price)
    return order
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{order}) = JSON3.Mutable()
JSON3.StructType(::Type{stopLossOnFill}) = JSON3.Mutable()
JSON3.StructType(::Type{marketOrderRequest}) = JSON3.Struct()
JSON3.StructType(::Type{orderRequest}) = JSON3.Struct()

"Places an order"
function placeOrder(config, instrument, units, TIF="FOK", priceBound="1.23", positionFill="DEFAULT")
    data = marketOrderRequest("MARKET", instrument, units, TIF, priceBound, positionFill)
    data = orderRequest(data)
    r = HTTP.request("POST", string("https://", config.hostname, "/v3/accounts/", config.account, "/orders"),
    ["Authorization" => string("Bearer ", config.token),
    "Accept-Datetime-Format" => config.datetime, "Content-Type" => "application/json"], JSON3.write(data))
    if r.status != 200
        println(r.status)
    end
end

end
