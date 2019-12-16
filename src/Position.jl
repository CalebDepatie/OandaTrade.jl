module Position
using JSON3

"Individual data for positions (A Long or Short)"
mutable struct posData
    pl # The profit / Loss
    resettablePL # Profit / Loss since last reset
    units # Number of units in the trade
    unrealizedPL # Unrealized profit / loss of position

    posData() = new()
end

"Detailed Position struct from Oanda"
mutable struct position
    instrument # The instrument
    # I have both of the following to enable people with hedging enabled
    long::posData # Data for a Long trade on the position
    short::posData # Data for a Short trade on the position
    pl # The profit / loss for this position
    resettablePL # The profit / loss since last reset for this position
    unrealizedPL # The total unrealised profit / loss for this position

    position() = new()
end

"Coerce a given Position into its proper types (Used internally)"
function coercePos(pos::position)
    pos.long.pl = parse(Float32, pos.long.pl)
    pos.long.resettablePL = parse(Float32, pos.long.resettablePL)
    pos.long.units = parse(Int32, pos.long.units)
    pos.long.unrealizedPL = parse(Float32, pos.long.unrealizedPL)

    pos.short.pl = parse(Float32, pos.short.pl)
    pos.short.resettablePL = parse(Float32, pos.short.resettablePL)
    pos.short.units = parse(Int32, pos.short.units)
    pos.short.unrealizedPL = parse(Float32, pos.short.unrealizedPL)

    pos.pl = parse(Float32, pos.pl)
    pos.resettablePL = parse(Float32, pos.resettablePL)
    pos.unrealizedPL = parse(Float32, pos.unrealizedPL)

    return pos
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{Position.position}) = JSON3.Mutable()
JSON3.StructType(::Type{Position.posData}) = JSON3.Mutable()

end
