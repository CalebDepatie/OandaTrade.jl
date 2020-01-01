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

    tpages.from = DateTime(tpages.from[1:23], RFC) #DateTime has milliseconds precision. Can only use 23 characters...
    tpages.to = DateTime(tpages.to[1:23], RFC)
    tpages.lastTransactionID = parse(Int,tpages.lastTransactionID)

    return tpages

end

"""
    getTransactionPages(config::config; from::DateTime=nothing, to::DateTime=Dates.now(), pageSize::Int=100, type::String=nothing)

    Returns a struct. Field :pages includes the urls for getting the transactions in the given timeframe

# Example

    getTransactionPages(userdata, from=DateTime(2019,5,31),type="MARKET_ORDER,STOP_LOSS_ORDER")
"""
function getTransactionPages(config; from::Union{DateTime,Nothing}=nothing, to::DateTime=Dates.now(), pageSize::Int=100, type::Union{String,Nothing}=nothing)

    q = Dict("to"=>Dates.format(to, "yyyy-mm-ddTHH:MM:SS.000000000Z"),"pageSize"=>pageSize)
    !isnothing(from) && push!(q,"from"=>Dates.format(from, "yyyy-mm-ddTHH:MM:SS.000000000Z"))
    !isnothing(type) && push!(q,"type"=>type)

    r = HTTP.get(string("https://", config.hostname, "/v3/accounts/", config.account, "/transactions"),
    ["Authorization" => string("Bearer ", config.token),"Accept-Datetime-Format" => "RFC3339"]; query = q)

    if r.status != 200
        println(r.status)
    end

    return JSON3.read(r.body,transactionPages) |> coerceTransactionPages
end
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/{transactionID} Endpoint
#------------------------------------------------------------------------------------
mutable struct transaction
    transaction
    lastTransactionID

    transaction() = new()
end

function getTransaction(config::config,tID::Int)
    
end
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/idrange  Endpoint
#/accounts/{accountID}/transactions/sinceid  Endpoint
#------------------------------------------------------------------------------------
mutable struct transactions
    transactions
    lastTransactionID

    transactions() = new()
end

function getTransactions(config::config,fromID::Int,toID::Int)
    
end

function getTransactions(config::config,sinceID::Int)
    
end

end #Module