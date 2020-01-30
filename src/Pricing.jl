module Pricing
using HTTP, JSON3, Dates, CodecZlib

"Ask / Bid pricing data"
mutable struct priceData
    price # Price of the ask / bid
    liquidity # liquidity of the ask / bid

    priceData() = new()
end

"Pricing data of an instrument"
mutable struct price
    type # Type
    time # Time of the price update
    bids::Vector{priceData} # Bid information
    asks::Vector{priceData} # Ask information
    closeoutBid # Closeout bid price
    closeoutAsk # Closeout Ask price
    status # Status of this instrument
    tradeable # Can you trade this instrument

    price() = new()
end

"Needed for JSON parsing"
mutable struct priceTopLayer
    prices::Vector{price} # Prices

    priceTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{price}) = JSON3.Mutable()
JSON3.StructType(::Type{priceTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{priceData}) = JSON3.Mutable()

"Coerce pricing data into proper types"
function coercePrice(price::price)
    # Coerce Asks
    temp = Vector{priceData}()
    for ask in price.asks
        ask.price = parse(Float32, ask.price)
        push!(temp, ask)
    end
    price.asks = temp
    # Coerce Bids
    temp = Vector{priceData}()
    for bid in price.bids
        bid.price = parse(Float32, bid.price)
        push!(temp, bid)
    end
    price.bids = temp
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")
    price.time = DateTime(first(price.time, 23), RFC)
    price.closeoutBid = parse(Float32, price.closeoutBid)
    price.closeoutAsk = parse(Float32, price.closeoutAsk)
    return price
end

"Exception thrown when the market is closed on the weekend"
struct ClosedMarketException <: Exception end

"Get the most recent price update of an instrument"
function getPrice(config, instrument)
    dt = Dates.now()
    if Dates.dayofweek(dt) >= 5
        if Dates.dayofweek(dt) == 5 & Dates.hour(dt) < 4
        elseif Dates.dayofweek(dt) == 7 & Dates.hour(dt) >= 5
        else
            throw(ClosedMarketException())
        end
    end

    query = string("instruments=", instrument)
    r = HTTP.request(
        "GET",
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/pricing?",
            query,
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ],
    )
    data = JSON3.read(r.body, priceTopLayer)
    temp = Vector{price}()
    for priceData in data.prices
        push!(temp, coercePrice(priceData))
    end
    return temp[end]
end

end
