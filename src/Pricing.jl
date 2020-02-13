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

"Exception thrown when the market is closed on the weekend"
struct ClosedMarketException <: Exception end

"""
    function getPrice(config, instruments)

Get the most recent price update of an instrument


"""
function getPrice(config::config, instruments::Vector{String})
    #= Do we need to check this every time? 
    dt = Dates.now()
    if Dates.dayofweek(dt) >= 5  
        if Dates.dayofweek(dt) == 5 & Dates.hour(dt) < 4
        elseif Dates.dayofweek(dt) == 7 & Dates.hour(dt) >= 5
        else
            throw(ClosedMarketException())
        end
    end
    =#
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


# ------------------------------------------------------------------------------------
# /accounts/{accountID}/candles/latest Endpoint
# ------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------
# /accounts/{accountID}/instrument/{instrument}/candle Endpoint
# ------------------------------------------------------------------------------------


end #module