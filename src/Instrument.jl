module Instrument

using Dates

#/instruments/{instrument}/candles Endpoint

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

    candles()=new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{candlestickdata}) = JSON3.Mutable()
JSON3.StructType(::Type{candlestick}) = JSON3.Mutable()
JSON3.StructType(::Type{candles}) = JSON3.Mutable()

# Conversions to proper Julia types

function coerceCandleStick(config,candle::candlestick)

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    candle.time = (config.datetime == "RFC3339" ? DateTime(candle.time, RFC) : unix2datetime(candle.time))
    isdefined(candle,:bid) && (candle.bid = coerceCandleStickData(candle.bid))
    isdefined(candle,:ask) && (candle.ask = coerceCandleStickData(candle.ask))
    isdefined(candle,:mid) && (candle.mid = coerceCandleStickData(candle.mid))

    return candle
end

function coerceCandleStickData(candleData::candlestickdata)

   candleData.o = parse(Float32,candleData.o)
   candleData.h = parse(Float32,candleData.h)
   candleData.l = parse(Float32,candleData.l)
   candleData.c = parse(Float32,candleData.c)

   return candleData
end

"""
    getcandles(config::config, instrument::String, lastn::Int = 10, price::String = "M", granularity::String = "M5";kw...)
    getcandles(config::config, instrument::String, from::DateTime, to::DateTime, price::String = "M", granularity::AbstractString = "M5";kw...)
    getcandles(config::config, instrument::String, from::DateTime, n::Int = 10, price::String = "M", granularity::AbstractString = "M5";kw...)
    getcandles(config::config, instrument::String, n::Int, to::DateTime, price::String = "M", granularity::AbstractString = "M5";kw...)
    getcandles(config::config, instrument::String, from::DateTime, price::String = "M", granularity::AbstractString = "M5";kw...)

Get candle information of a given instrument and returns a Candle struct
Information includes: time, granularity, open, high, low, close, volume and a complete indicator

getcandles has five methods differing in how to request the number of candles to retrieve
    - lastn: last "n" candles
    - from and to: candles in a time interval specified by two dates
    - from and "n", to and "n": n candles from o to the specified date
    - from: all candles form the specified date

# Arguments
    - pair: a valid instrument (e.g. "EUR_USD")
    - price: "A" for ask, "B" for bid, "M" for medium
    - granularity: a valid time interval ["S5","S10","S15","S30","M1","M2","M4","M5","M10","M15","M30",
                 "H1","H2","H3","H4","H6","H8","H12","D","W","M"]

# Keyword Arguments (TODO)
    smooth, includeFirst, dailyaligment, alignmentTimezone, weeklyAlignment

# Examples
    getcandles(userdata,"EUR_USD",10,"A","M30")
    getcandles(userdata,"EUR_JPY",DateTime(2019,1,1),DateTime(2019,1,31),"B","H1")
    getcandles(userdata,"EUR_CHF",10,DateTime(2019,1,31),"AB","M5")
    getcandles(userdata,"EUR_USD",DateTime(2019,1,31),10,"A","M30")
    getcandles(userdata,"EUR_USD",DateTime(2019,1,31),"M","D")

"""
#Is it possible to handle combinations of count,fromDate, toDate with fewer methods?
function getcandles(config, instrument::String, lastn::Int, price::String="M", granularity::String="M5";kw...)

    #TODO kw-> smooth::Bool, includeFirst::Bool, dailyaligment::Int, alignmentTimezone::String, weeklyAlignment::String)

    r = HTTP.get(string("https://", config.hostname, "/v3/instruments/", instrument, "/candles"),
        ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime];
        query = Dict("price" => price, "granularity" => granularity, "count" => lastn))
    
    if r.status != 200
        println(r.status)
    end    
        
    temp = JSON3.read(r.body,candles)

    #type coersions
    for c in temp.candles
       c = coerceCandleStick(config,c)
    end

    return temp

end

function getcandles(config,instrument::String, from::DateTime, to::DateTime, price::String = "M", granularity::String = "M5";kw...)
    
    #TODO kw-> smooth::Bool, includeFirst::Bool, dailyaligment::Int, alignmentTimezone::String, weeklyAlignment::String)
    
    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")
    to = Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(string("https://", config.hostname, "/v3/instruments/", instrument, "/candles"),
        ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime];
        query = Dict("price" => price, "granularity" => granularity,"fromDate" => from, "toDate" => to))
        
    if r.status != 200
        println(r.status)
    end    

    temp = JSON3.read(r.body,candles)

    #type coersions
    for c in temp.candles
       c = coerceCandleStick(config,c)
    end

    return temp
end

function getcandles(config, instrument::String, from::DateTime, n::Int, price::String = "M", granularity::String = "M5";kw...)
    
    #TODO kw-> smooth::Bool, includeFirst::Bool, dailyaligment::Int, alignmentTimezone::String, weeklyAlignment::String)
    
    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(string("https://", config.hostname, "/v3/instruments/", instrument, "/candles"),
        ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime];
        query = Dict("price" => price, "granularity" => granularity,"count" => n, "fromDate" => from))
        
    if r.status != 200
        println(r.status)
    end    

    temp = JSON3.read(r.body,candles)

    #type coersions
    for c in temp.candles
       c = coerceCandleStick(config,c)
    end

    return temp
end

function getcandles(config, instrument::String, n::Int,to::DateTime, price::String = "M", granularity::String = "M5";kw...)
    
    #TODO kw-> smooth::Bool, includeFirst::Bool, dailyaligment::Int, alignmentTimezone::String, weeklyAlignment::String)
    
    to = Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(string("https://", config.hostname, "/v3/instruments/", instrument, "/candles"),
        ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime];
        query = Dict("price" => price, "granularity" => granularity,"count" => n, "toDate" => to))
        
    if r.status != 200
        println(r.status)
    end    

    temp = JSON3.read(r.body,candles)

    #type coersions
    for c in temp.candles
       c = coerceCandleStick(config,c)
    end

    return temp
end

function getcandles(config, instrument::String, from::DateTime, price::String = "M", granularity::String = "M5";kw...)

    #TODO kw-> smooth::Bool, includeFirst::Bool, dailyaligment::Int, alignmentTimezone::String, weeklyAlignment::String)
    
    from = Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z")

    r = HTTP.get(string("https://", config.hostname, "/v3/instruments/", instrument, "/candles"),
        ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime];
        query = Dict("price" => price, "granularity" => granularity,"fromDate" => from))
        
    if r.status != 200
        println(r.status)
    end    

    temp = JSON3.read(r.body,candles)

    #type coersions
    for c in temp.candles
       c = coerceCandleStick(config,c)
    end

    return temp
end

#/instruments/{instrument}/orderBook Endpoint


end #Module
