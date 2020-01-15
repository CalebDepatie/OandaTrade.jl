module Position
using JSON3, HTTP

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

"Top layer for positions endpoint"
mutable struct positionTopLayer
    positions::Vector{position}

    positionTopLayer() = new()
end

"Top layer for positions endpoint"
mutable struct positionTopLayerSingle
    position::position

    positionTopLayerSingle() = new()
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
JSON3.StructType(::Type{position}) = JSON3.Mutable()
JSON3.StructType(::Type{positionTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{positionTopLayerSingle}) = JSON3.Mutable()
JSON3.StructType(::Type{posData}) = JSON3.Mutable()

"""
    listPositions(config)

Returns a list of current positions
"""
function listPositions(config)
    r = HTTP.request(
        "GET",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/positions",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ],
    )
    data = JSON3.read(r.body, positionTopLayer)
    data = data.positions

    temp = Vector{position}()
    for pos in data
        pos = coercePos(pos)
        push!(temp, pos)
    end

    return temp
end

"""
    listOpenPositions(config)

Returns a list of current positions that have an open trade
"""
function listOpenPositions(config)
    r = HTTP.request(
        "GET",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/openPositions",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ],
    )
    data = JSON3.read(r.body, positionTopLayer)
    data = data.positions

    temp = Vector{position}()
    for pos in data
        pos = coercePos(pos)
        push!(temp, pos)
    end

    return temp
end

"""
    getPosition(config, instrument)

Returns position data for a specified instrument
"""
function getPosition(config, instrument)
    r = HTTP.request(
        "GET",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/positions/",
            instrument,
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ],
    )
    data = JSON3.read(r.body, positionTopLayerSingle)

    data = coercePos(data.position)

    return data
end

"""
    closePositionFull(config, instrument, long=true)

Closes a position completely
"""
function closePositionFull(config, instrument, long=true)
    data = ""
    if long
        data = "{\"longUnits\": \"ALL\"}"
    else
        data = "{\"shortUnits\": \"ALL\"}"
    end
    r = HTTP.request(
        "PUT",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/positions/",
            instrument,
            "/close"
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
          "Content-Type" => "application/json",
        ],
        data,
    )

    return true
end

"""
    closePosition(config, instrument, LongUnits=NONE, ShortUnits=NONE)

Closes a positions units based on input
"""
function closePosition(config, instrument, longUnits="NONE", shortUnits="NONE")
    r = HTTP.request(
        "PUT",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/positions/",
            instrument,
            "/close"
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
          "Content-Type" => "application/json",
        ],
        string("{\"longUnits\": \"", longUnits,"\",\n\"shortUnits\": \"", shortUnits,"\"}"),
    )

    return true
end

end
