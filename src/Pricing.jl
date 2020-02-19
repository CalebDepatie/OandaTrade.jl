module Pricing
using HTTP, JSON3, Dates

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pricing Endpoint
# ------------------------------------------------------------------------------------

"Ask / Bid pricing data"
mutable struct priceBucket
    price # Price of the ask / bid
    liquidity # liquidity of the ask / bid

    priceBucket() = new()
end

"Pricing data of an instrument"
mutable struct price
    type # Type
    instrument
    time # Time of the price update
    bids::Vector{priceBucket} # Bid information
    asks::Vector{priceBucket} # Ask information
    closeoutBid # Closeout bid price
    closeoutAsk # Closeout Ask price
    tradeable # Can you trade this instrument

    price() = new()
end

"Needed for JSON parsing"
mutable struct priceTopLayer
    prices::Vector{price} # Prices
    time

    priceTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{priceBucket}) = JSON3.Mutable()
JSON3.StructType(::Type{price}) = JSON3.Mutable()
JSON3.excludes(::Type{price})=(:status,:quoteHomeConversionFactors,:unitsAvailable) #Ignore deprecated fields
JSON3.StructType(::Type{priceTopLayer}) = JSON3.Mutable()

"Coerce pricing data into proper types"
function coercePrice(price::price)
    # Coerce Asks
    for ask in price.asks
        ask.price = parse(Float32, ask.price)
    end
    # Coerce Bids
    for bid in price.bids
        bid.price = parse(Float32, bid.price)
    end
    price.time = DateTime(first(price.time, 23), Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ"))
    price.closeoutBid = parse(Float32, price.closeoutBid)
    price.closeoutAsk = parse(Float32, price.closeoutAsk)

    return price
end

"""
    function getPrice(config, instruments)

Get the most recent price update of an instrument

# Arguments
    - 'config::config': a valid struct with user configuracion data
    - 'instruments::Vector{String}': a vector of valid pairs (e.g. ["EUR_USD","EUR_JPY"])

#Example

    getPrice(userconfig, ["EUR_USD","EUR_JPY"])
    
"""
function getPrice(config::config, instruments::Vector{String})

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/",config.account,"/pricing?instruments=", join(instruments,",")),
                ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime,],)

    data = JSON3.read(r.body, priceTopLayer)

    for priceData in data.prices
        coercePrice(priceData)
    end

    return data.prices #Does not return 'since' datetime

end
# ------------------------------------------------------------------------------------
# /accounts/{accountID}/pricing/stream Endpoint
# ------------------------------------------------------------------------------------
"""
    function streamprice(f, config , instruments)

Returns a stream of price objects and apply a function to each one of them

# Arguments
    - 'f::Function': a function to apply to each price struct object. Streamprice accepts do block format
    - 'config::config': a valid struct with user configuracion data
    - 'instruments::Vector{String}': a vector of valid pairs (e.g. ["EUR_USD","EUR_JPY"])

#Example

    streamprice(userconfig, ["EUR_JPY"]) do price
        println(price)
    end
"""
function streamPrice(f::Function, config::config,instruments::Vector{String})

@async HTTP.open("GET", 
        string("https://", config.streamingHostname, "/v3/accounts/",config.account,"/pricing/stream?instruments=", join(instruments,",")),
        ["Authorization" => string("Bearer ", config.token)]) do io
            for line in eachline(io)
                p = JSON3.read(line, price)
                p.type != "HEARTBEAT" && f(p) #Cleans HEARTBEAT ticks so that only prices are sent to f
            end
        end
end


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/candles/latest Endpoint
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/instrument/{instrument}/candle Endpoint
# ------------------------------------------------------------------------------------


end #module