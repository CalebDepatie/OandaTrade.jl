module Order
using JSON3

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

"Coerce a given Order into its proper types (Used internally)"
function coerceOrder(order::order)
    order.price = parse(Float32, order.price)
    order.units = parse(Int32, order.units)
    order.stopLossOnFill.price = parse(Float32, order.stopLossOnFill.price)
    return order
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{Order.order}) = JSON3.Mutable()
JSON3.StructType(::Type{Order.stopLossOnFill}) = JSON3.Mutable()

end
