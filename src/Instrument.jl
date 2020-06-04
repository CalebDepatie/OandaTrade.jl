module Instrument

using HTTP, JSON3, Dates, CodecZlib

export getCandles, getOrderBook, getPositionBook

#------------------------------------------------------------------------------------
#/instruments/{instrument}/candles Endpoint
#------------------------------------------------------------------------------------
mutable struct candlestickdata
    o   #open
    h   #high
    l   #low
    c   #close

    candlestickdata() = new()
end

mutable struct candlestick
    time
    bid::candlestickdata
    ask::candlestickdata
    mid::candlestickdata
    volume
    complete

    candlestick() = new()
end

mutable struct candles
    instrument
    granularity
    candles::Vector{candlestick}

    candles() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{candlestickdata}) = JSON3.Mutable()
JSON3.StructType(::Type{candlestick}) = JSON3.Mutable()
JSON3.StructType(::Type{candles}) = JSON3.Mutable()

# Conversions to proper Julia types
function coerceCandleStick(config, candle::candlestick)

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    candle.time = DateTime(candle.time, RFC)
    isdefined(candle, :bid) && (candle.bid = coerceCandleStickData(candle.bid))
    isdefined(candle, :ask) && (candle.ask = coerceCandleStickData(candle.ask))
    isdefined(candle, :mid) && (candle.mid = coerceCandleStickData(candle.mid))

    return candle
end

function coerceCandleStickData(candleData::candlestickdata)

    candleData.o = parse(Float32, candleData.o)
    candleData.h = parse(Float32, candleData.h)
    candleData.l = parse(Float32, candleData.l)
    candleData.c = parse(Float32, candleData.c)

    return candleData
end

"""
    getCandles(config::config, instrument::String, lastn::Int = 10, price::String = "M", granularity::String = "M5";kwargs...)
    getCandles(config::config, instrument::String, from::DateTime, to::DateTime, price::String = "M", granularity::AbstractString = "M5";kwargs...)
    getCandles(config::config, instrument::String, from::DateTime, n::Int = 10, price::String = "M", granularity::AbstractString = "M5";kwargs...)
    getCandles(config::config, instrument::String, n::Int, to::DateTime, price::String = "M", granularity::AbstractString = "M5";kwargs...)
    getCandles(config::config, instrument::String, from::DateTime, price::String = "M", granularity::AbstractString = "M5";kwargs...)

Get candle information of a given instrument and returns a Candle struct
Information includes: time, granularity, open, high, low, close, volume and a complete indicator

getCandles has five ways to select the candles to retrieve
- lastn: last "n" candles
- from and to: candles in a time interval specified by two dates
- from and "n", to and "n": n candles from or to the specified date
- from: all candles from the specified date"A" for ask, "B" for bid, "M" for medium or a combination ot them

# Arguments
- 'config::config': a valid struct with user configuration data
- 'instrument::String": a valid instrument (e.g. "EUR_USD")
- 'price::String': "A" for ask, "B" for bid, "M" for mid or a combination of them
- 'granularity::String': a valid time interval ["S5","S10","S15","S30","M1","M2","M4","M5","M10","M15","M30","H1","H2","H3","H4","H6","H8","H12","D","W","M"]

# Keyword Arguments
- 'smooth::Bool'
- 'includeFirst::Bool'
- 'dailyaligment::Int'
- 'alignmentTimezone::String'
- 'weeklyAlignment::String'

# Examples
    getCandles(userdata,"EUR_USD",10,"A","M30")
    getCandles(userdata,"EUR_JPY",DateTime(2019,1,1),DateTime(2019,1,31),"B","H1")
    getCandles(userdata,"EUR_USD",DateTime(2019,1,31),10,"A","M30")
    getCandles(userdata,"EUR_CHF",10,DateTime(2019,1,31),"AB","M5")
    getCandles(userdata,"EUR_USD",DateTime(2019,1,31),"M","D")

"""
function getCandles(
    config,
    instrument::String,
    lastn::Int,
    price::String = "M",
    granularity::String = "M5";
    kwargs...,
)
    #Is it possible to handle combinations of count,fromDate, toDate with fewer methods?
    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/candles",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = push!(
            Dict(),
            "price" => price,
            "granularity" => granularity,
            "count" => lastn,
            kwargs...,
        ),
    )

    temp = JSON3.read(r.body, candles)

    #type coersions
    for c in temp.candles
        c = coerceCandleStick(config, c)
    end

    return temp

end

function getCandles(
    config,
    instrument::String,
    from::DateTime,
    to::DateTime,
    price::String = "M",
    granularity::String = "M5";
    kwargs...,
)

    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")
    to = Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/candles",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = push!(
            Dict(),
            "price" => price,
            "granularity" => granularity,
            "fromDate" => from,
            "toDate" => to,
            kwargs...,
        ),
    )

    temp = JSON3.read(r.body, candles)

    #type coersions
    for c in temp.candles
        c = coerceCandleStick(config, c)
    end

    return temp
end

function getCandles(
    config,
    instrument::String,
    from::DateTime,
    n::Int,
    price::String = "M",
    granularity::String = "M5";
    kwargs...,
)

    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/candles",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = push!(
            Dict(),
            "price" => price,
            "granularity" => granularity,
            "count" => n,
            "fromDate" => from,
            kwargs...,
        ),
    )

    temp = JSON3.read(r.body, candles)

    #type coersions
    for c in temp.candles
        c = coerceCandleStick(config, c)
    end

    return temp
end

function getCandles(
    config,
    instrument::String,
    n::Int,
    to::DateTime,
    price::String = "M",
    granularity::String = "M5";
    kwargs...,
)

    to = Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/candles",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = push!(
            Dict(),
            "price" => price,
            "granularity" => granularity,
            "count" => n,
            "toDate" => to,
            kwargs...,
        ),
    )

    temp = JSON3.read(r.body, candles)

    #type coersions
    for c in temp.candles
        c = coerceCandleStick(config, c)
    end

    return temp
end

function getCandles(
    config,
    instrument::String,
    from::DateTime,
    price::String = "M",
    granularity::String = "M5";
    kwargs...,
)

    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/candles",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = push!(
            Dict(),
            "price" => price,
            "granularity" => granularity,
            "fromDate" => from,
            kwargs...,
        ),
    )

    temp = JSON3.read(r.body, candles)

    #type coersions
    for c in temp.candles
        c = coerceCandleStick(config, c)
    end

    return temp
end
#------------------------------------------------------------------------------------
#/instruments/{instrument}/orderBook Endpoint
#------------------------------------------------------------------------------------
mutable struct orderBookBucket
    price
    longCountPercent
    shortCountPercent

    orderBookBucket() = new()
end

mutable struct orderBook
    instrument
    time
    price
    bucketWidth
    buckets::Vector{orderBookBucket}

    orderBook() = new()
end

mutable struct orderBookTopLayer
    orderBook::orderBook

    orderBookTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{orderBookTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{orderBook}) = JSON3.Mutable()
JSON3.StructType(::Type{orderBookBucket}) = JSON3.Mutable()

# Conversions to proper Julia types
function coerceOrderBook(ob::orderBook)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSZ")

    ob.time = DateTime(ob.time, RFC)
    ob.price = parse(Float32, ob.price)
    ob.bucketWidth = parse(Float32, ob.bucketWidth)
    for bucket in ob.buckets
        bucket = coerceOrderBookBucket(bucket)
    end

    return ob
end

function coerceOrderBookBucket(bucket::orderBookBucket)
    bucket.price = parse(Float32, bucket.price)
    bucket.longCountPercent = parse(Float32, bucket.longCountPercent)
    bucket.shortCountPercent = parse(Float32, bucket.shortCountPercent)

    return bucket
end

"""
    getOrderBook(config::config,instrument::String,time::DateTime=now())

# Example
    getOrderBook(userdata,"EUR_CHF",DateTime(2017,1,31,4,00))

"""
function getOrderBook(config, instrument::String, time::DateTime = now())

    time = Dates.format(time, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/orderBook",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = Dict("time" => time),
    )

    #TODO: Fix to check for gzip headers
    #unzipr = GzipDecompressorStream(IOBuffer(String(r.body))) #Response is compressed

    #temp = JSON3.read(unzipr, orderBookTopLayer)

    temp = JSON3.read(r.body, orderBookTopLayer)

    temp.orderBook = coerceOrderBook(temp.orderBook)

    return temp.orderBook
end
#------------------------------------------------------------------------------------
#/instruments/{instrument}/positionBook Endpoint
#------------------------------------------------------------------------------------
mutable struct positionBookBucket
    price
    longCountPercent
    shortCountPercent

    positionBookBucket() = new()
end

mutable struct positionBook
    instrument
    time
    price
    bucketWidth
    buckets::Vector{positionBookBucket}

    positionBook() = new()
end

mutable struct positionBookTopLayer
    positionBook::positionBook

    positionBookTopLayer() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{positionBookTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{positionBook}) = JSON3.Mutable()
JSON3.StructType(::Type{positionBookBucket}) = JSON3.Mutable()

# Conversions to proper Julia types
function coercePositionBook(ob::positionBook)
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SSZ")

    ob.time = DateTime(ob.time, RFC)
    ob.price = parse(Float32, ob.price)
    ob.bucketWidth = parse(Float32, ob.bucketWidth)
    for bucket in ob.buckets
        bucket = coercePositionBookBucket(bucket)
    end

    return ob
end

function coercePositionBookBucket(bucket::positionBookBucket)
    bucket.price = parse(Float32, bucket.price)
    bucket.longCountPercent = parse(Float32, bucket.longCountPercent)
    bucket.shortCountPercent = parse(Float32, bucket.shortCountPercent)

    return bucket
end

"""
    getPositionBook(config::config,instrument::String,time::DateTime=now())

# Example
    getPositionBook(userdata,"EUR_CHF",DateTime(2017,1,31,4,00))

"""
function getPositionBook(config, instrument::String, time::DateTime = now())

    time = Dates.format(time, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/instruments/",
            instrument,
            "/positionBook",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => config.datetime,
        ];
        query = Dict("time" => time),
    )

    #TODO: Check for gzip headers
    #unzipr = GzipDecompressorStream(IOBuffer(String(r.body))) #Response is compressed

    #temp = JSON3.read(unzipr, positionBookTopLayer)

    temp = JSON3.read(r.body, positionBookTopLayer)

    temp.positionBook = coercePositionBook(temp.positionBook)

    return temp.positionBook
end

end #Module
