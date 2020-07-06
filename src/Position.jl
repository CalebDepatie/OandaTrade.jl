module Position
using JSON3, HTTP

export listPositions, listOpenPositions, getPosition, closePosition, closePositionFull

"""
Individual data for positions (A Long or Short)

# Fields
- 'pl': Profit / Loss
- 'resettablePL': Profit / Loss since last reset
- 'units': Number of units in the trade
- 'unrealizedPL': Unrealized profit / loss in the posistion
"""
mutable struct posData
    pl # The profit / Loss
    resettablePL # Profit / Loss since last reset
    units # Number of units in the trade
    unrealizedPL # Unrealized profit / loss of position

    posData() = new()
end

"""
Detailed Position struct from Oanda

# Fields
- 'instrument': The instrument of the position
- 'long::posData': Data for longs on the position
- 'short::posData': Data for shorts on the position
- 'pl': Overall profit / loss for the position
- 'resettablePL': Profit / Loss since last reset
- 'unrealizedPL': Unrealized profit / loss in the posistion
"""
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

Returns an object of type 'Vector{position}'

# Arguments
- 'config::config': A valid config object
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

Returns an object of 'Vector{position}'

# Arguments
- 'config::config': A valid config object
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

Returns an object of type 'position'

# Arguments
- 'config::config': A valid config object
- 'instrument': The instrument to get info from
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

Returns true on success

# Arguments
- 'config::config': A valid config object
- 'instrument': instrument to close
- 'long::Bool': True to close long false to close short
"""
function closePositionFull(config, instrument, long::Bool=true)
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

Returns true on success

# Arguments
- 'config::config': A valid config object
- 'instrument': The instrument to act on
- 'longUnits': The number of long units to close
- 'shortUnits': The number of short units to close
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
