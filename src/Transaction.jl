module Transaction

using HTTP, JSON3, Dates
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions Endpoint
#------------------------------------------------------------------------------------
mutable struct transactionPages
    from
    to
    pageSize
    type::Vector{String}
    count
    pages::Vector{String}
    lastTransactionID

    transactionPages() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{transactionPages}) = JSON3.Mutable()

# Conversions to proper Julia types
function coerceTransactionPages(tpages::transactionPages)

    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    tpages.from = DateTime(first(tpages.from, 23), RFC) #DateTime has milliseconds precision. Can only use 23 characters...
    tpages.to = DateTime(first(tpages.to, 23), RFC)
    tpages.lastTransactionID = parse(Int, tpages.lastTransactionID)

    return tpages
end

"""
    getTransactionPages(config::config; from::DateTime=nothing, to::DateTime=Dates.now(), pageSize::Int=100, type::String=nothing)

Return a struct. Field ':pages' includes the urls for requesting the transactions data in the given timeframe

# Example
    getTransactionPages(userdata, from=DateTime(2019,5,31),type="MARKET_ORDER,STOP_LOSS_ORDER")
"""
function getTransactionPages(
    config;
    from::Union{DateTime,Nothing} = nothing,
    to::DateTime = Dates.now(),
    pageSize::Int = 100,
    type::Union{String,Nothing} = nothing,
)

    q = Dict(
        "to" => Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z"),
        "pageSize" => pageSize,
    )
    !isnothing(from) && push!(
        q,
        "from" => Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z"),
    )
    !isnothing(type) && push!(q, "type" => type)

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/transactions",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => "RFC3339",
        ];
        query = q,
    )

    return JSON3.read(r.body, transactionPages) |> coerceTransactionPages
end
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/{transactionID} Endpoint
#------------------------------------------------------------------------------------
mutable struct transaction
    transaction::Dict{String,Any}
    lastTransactionID

    transaction() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{transaction}) = JSON3.Mutable()

"Recursive coersion of transaction Dictionaries to proper Julia types"
function coerceTransactionDict(tDict::Dict{String,Any}) #Also used in getTransactions endpoints

    valueFields = [
        "price",
        "priceBound",
        "fullVWAP",
        "distance",
        "closeoutBid",
        "closeoutAsk",
        "marginRate",
        "initialMarginRequired",
        "requestedUnits",
        "liquidity",
        "gainQuoteHomeConversionFactor",
        "lossQuoteHomeConversionFactor",
        "AccountBalance",
        "amount",
        "financing",
        "pl",
        "commission",
        "guaranteedExecutionFee",
        "halfSpreadCost",
        "dividend",
        "realizedPL",
        "bidLiquidityUsed",
        "askLiquidityUsed",
    ]

    timeFields = ["timestamp", "time", "gtdTime"]
    RFC = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sssssssssZ")

    for (key, value) in tDict
        if eltype(value) == Pair{String,Any}
            tDict[key] = coerceTransactionDict(tDict[key]) #Recursion for Dictionaries inside a transaction field
        elseif eltype(value) == Any #'asks' & 'bids' in 'fullPrice' have an array of liquidity, prices
            tDict[key] = collect(coerceTransactionDict.(tDict[key]))
        elseif key in valueFields
            tDict[key] = parse(Float32, value)
        elseif key == "units" && value != "ALL"
            tDict[key] = parse(Float32, value)
        elseif key in timeFields
            tDict[key] = DateTime(first(value, 23), RFC)
        end
    end

    return tDict
end

"""
    getTransaction(config::config, tID::Int)

Return a Dictionary with the transaction data

# Example
    getTransaction(userdata,4)
"""
function getTransaction(config, tID::Int)

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/transactions/",
            string(tID),
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => "RFC3339",
        ],
    )

    temp = JSON3.read(r.body, transaction)
    temp.transaction = coerceTransactionDict(temp.transaction)
    return temp
end
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/idrange  Endpoint
#/accounts/{accountID}/transactions/sinceid  Endpoint
#------------------------------------------------------------------------------------

mutable struct transactions
    transactions::Array{Dict{String,Any},1}
    lastTransactionID

    transactions() = new()
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{transactions}) = JSON3.Mutable()

"""
    getTransactions(config::config, fromID::Int, toID::Int, type::Union{String,Nothing}=nothing)
    getTransactions(config::config, sinceID::Int, type::Union{String,Nothing}=nothing)

Return an array of Dictionaries with the transactions data

# Examples
    getTransactions(userdata,3,"MARKET_ORDER,STOP_LOSS_ORDER")
    getTransactions(userdata,2,10)
"""
function getTransactions(
    config,
    fromID::Int,
    toID::Int,
    type::Union{String,Nothing} = nothing,
)

    q = Dict("from" => string(fromID), "to" => string(toID))
    !isnothing(type) && push!(q, "type" => type)

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/transactions/idrange",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => "RFC3339",
        ];
        query = q,
    )

    temp = JSON3.read(r.body, transactions)

    for dict in temp.transactions
        dict = coerceTransactionDict(dict)
    end

    return temp
end

function getTransactions(
    config,
    sinceID::Int,
    type::Union{String,Nothing} = nothing,
)

    q = Dict("id" => string(sinceID))
    !isnothing(type) && push!(q, "type" => type)

    r = HTTP.get(
        string(
            "https://",
            config.hostname,
            "/v3/accounts/",
            config.account,
            "/transactions/sinceid",
        ),
        [
         "Authorization" => string("Bearer ", config.token),
         "Accept-Datetime-Format" => "RFC3339",
        ];
        query = q,
    )

    temp = JSON3.read(r.body, transactions)

    for dict in temp.transactions
        dict = coerceTransactionDict(dict)
    end

    return temp
end
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/stream Endpoint
#------------------------------------------------------------------------------------

end #Module
