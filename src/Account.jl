module Account

import HTTP, JSON3, Dates

# If I can get around the include statements I would like to
include("Position.jl")
include("Trade.jl")
include("Order.jl")

# TODO: Add strict types / Add type of coersion

"""
The account struct given by Oanda

# Fields
- NAV: The Net Asset Value of an account
- alias: User defined alias if one exists
- balance: Current Account Balance
- createdByUserID: The User ID of the account creator
- createdTime: The time the account was created
- currency: The primary currency of the account
- hedgingEnabled: If the account is allowed to hedge
- id: The account ID
- lastTransactionID: The last transaction ID
- marginAvailable: The margin still available on the account
- marginCloseoutMarginUsed: The closeout margin used
- marginCloseoutNAV: Margins closeout NAV
- marginCloseoutPercent: Margin closeout percent
- marginCloseoutPositionValue: Margin closeout position value
- marginCloseoutUnrealizedPL: Margin closeout unrealised profit/loss
- marginRate: The margin rate
- marginUsed: Amount of margin used
- openPositionCount: Number of open positions
- openTradeCount: Number of open trades
- orders: Orders of the account
- pendingOrderCount: Number of pending orders
- pl: The profit or loss over the lifetime of the account
- positionValue: Value of an accounts open positions
- positions: Positions of the account
- resettablePL: The resetable profit/loss since last reset
- trades: Trades of the account
- unrealizedPL: The unrealised profit/loss of the account
- withdrawalLimit: The withdrawal limit of the account
"""
mutable struct account
    NAV # The Net Asset Value of an account
    alias # User defined alias if one exists
    balance # Current Account Balance
    createdByUserID # The User ID of the account creator
    createdTime # The time the account was created
    currency # The primary currency of the account
    hedgingEnabled # If the account is allowed to hedge
    id # The account ID
    lastTransactionID # The last transaction ID
    marginAvailable # The margin still available on the account
    marginCloseoutMarginUsed # The closeout margin used
    marginCloseoutNAV # Margins closeout NAV
    marginCloseoutPercent # Margin closeout percent
    marginCloseoutPositionValue # Margin closeout position value
    marginCloseoutUnrealizedPL # Margin closeout unrealised profit/loss
    marginRate # The margin rate
    marginUsed # Amount of margin used
    openPositionCount # Number of open positions
    openTradeCount # Number of open trades
    orders::Vector{Order.order} # Orders of the account
    pendingOrderCount # Number of pending orders
    pl # The profit or loss over the lifetime of the account
    positionValue # Value of an accounts open positions
    positions::Vector{Position.position} # Positions of the account
    resettablePL # The resetable profit/loss since last reset
    trades::Vector{Trade.trade} # Trades of the account
    unrealizedPL # The unrealised profit/loss of the account
    withdrawalLimit # The withdrawal limit of the account

    account() = new()
end

"Nessecary for automatic JSON parsing, not for regular use"
mutable struct topLayer
    account::account

    topLayer() = new()
end

"The ID and tag of each account"
mutable struct accountListed
    id # Account id
    tags # Account Tags

    accountListed() = new()
end

"The list of accounts returned by Oanda"
mutable struct accountsList
    accounts::Vector{accountListed} # Array of accounts

    accountsList() = new()
end

"""
Tradeable Instrument data

# Fields
- displayName: Instrument name
- displayPrecision: Decimal precision of the instrument
- marginRate: Margin rate on the instrument
- maximumOrderUnits: Max units that can be ordered
- maximumPositionSize: max position size of the instrument
- maximumTrailingStopDistance: max trailing stop distance
- minimumTrailingStopDistance: min trailing stop distance
- name: Request usable instrument name
- pipLocation: current pip location
- tradeUnitsPrecision: Decimal precision of trade units
- type: Type of instrument
"""
mutable struct instrumentDetail
    displayName # Instrument name
    displayPrecision # Decimal precision of the instrument
    marginRate # Margin rate on the instrument
    maximumOrderUnits # Max units that can be ordered
    maximumPositionSize # max position size of the instrument
    maximumTrailingStopDistance # max trailing stop distance
    #minimumPositionSize # min position size of the instrument
    minimumTrailingStopDistance # min trailing stop distance
    name # Request usable instrument name
    pipLocation # current pip location
    tradeUnitsPrecision # Decimal precision of trade units
    type # Type of instrument

    instrumentDetail() = new()
end

"Nessecary for automatic JSON parsing, not for regular use"
mutable struct instrumentTopLayer
    instruments::Vector{instrumentDetail} # Tradable instruments

    instrumentTopLayer() = new()
end

"For configuring Accounts"
struct accountConfig
    alias::String
    marginRate::String
end

# Declaring JSON3 struct types
JSON3.StructType(::Type{account}) = JSON3.Mutable()
JSON3.StructType(::Type{topLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{accountsList}) = JSON3.Mutable()
JSON3.StructType(::Type{accountListed}) = JSON3.Mutable()
JSON3.StructType(::Type{instrumentDetail}) = JSON3.Mutable()
JSON3.StructType(::Type{instrumentTopLayer}) = JSON3.Mutable()
JSON3.StructType(::Type{accountConfig}) = JSON3.Struct()

"Coerce a given Account Summary into its proper types (Used for getAccount Method)"
function coerceAccountSummary(acc::account)
    acc.NAV = parse(Float32, acc.NAV)
    acc.balance = parse(Float32, acc.balance)
    acc.marginAvailable = parse(Float32, acc.marginAvailable)
    acc.marginCloseoutMarginUsed = parse(Float32, acc.marginCloseoutMarginUsed)
    acc.marginCloseoutNAV = parse(Float32, acc.marginCloseoutNAV)
    acc.marginCloseoutPercent = parse(Float32, acc.marginCloseoutPercent)
    acc.marginCloseoutPositionValue = parse(Float32, acc.marginCloseoutPositionValue)
    acc.marginCloseoutUnrealizedPL = parse(Float32, acc.marginCloseoutUnrealizedPL)
    acc.marginRate = parse(Float32, acc.marginRate)
    acc.marginUsed = parse(Float32, acc.marginUsed)
    #acc.openPositionCount = parse(Int32, acc.openPositionCount)
    #acc.openTradeCount = parse(Int32, acc.openTradeCount)
    #acc.pendingOrderCount = parse(Int32, acc.pendingOrderCount)
    acc.pl = parse(Float32, acc.pl)
    acc.positionValue = parse(Float32, acc.positionValue)
    acc.resettablePL = parse(Float32, acc.resettablePL)
    acc.unrealizedPL = parse(Float32, acc.unrealizedPL)
    acc.withdrawalLimit = parse(Float32, acc.withdrawalLimit)

    return acc
end

"Coerce a given Account into its proper types (Used for getAccount Method)"
function coerceAccount(acc::account)
    temp = Vector{Order.order}()
    for order in acc.orders
        order = Order.coerceOrder(order)
        push!(temp, order)
    end
    acc.orders = temp

    temp = Vector{Trade.trade}()
    for trade in acc.trades
        trade = Trade.coerceTrade(trade)
        push!(temp, trade)
    end
    acc.trades = temp

    temp = Vector{Position.position}()
    for position in acc.positions
        position = Position.coercePos(position)
        push!(temp, position)
    end
    acc.positions = temp

    acc = coerceAccountSummary(acc)

    return acc
end

"Coerce a given instrument detail into its proper types"
function coerceInstrumentDetail(inst::instrumentDetail)
    inst.marginRate = parse(Float32, inst.marginRate)
    inst.maximumOrderUnits = parse(Float64, inst.maximumOrderUnits)
    inst.maximumPositionSize = parse(Float32, inst.maximumPositionSize)
    inst.maximumTrailingStopDistance = parse(Float32, inst.maximumTrailingStopDistance)
    inst.minimumTrailingStopDistance = parse(Float32, inst.minimumTrailingStopDistance)

    return inst
end

"""
    listAccounts(config::config)

Returns a list of all account IDs and tags authorized for the given Token
"""
function listAccounts(config)
    r = HTTP.request("GET", string("https://", config.hostname, "/v3/accounts"),
    ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime])
    if r.status != 200
        println(r.status)
    end

    data = JSON3.read(r.body, accountsList)

    return data.accounts

end

"""
    getAccount(config::config)

Returns an Oanda account struct when given a valid config
"""
function getAccount(config)
    r = HTTP.request("GET", string("https://", config.hostname, "/v3/accounts/", config.account),
    ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime])
    if r.status != 200
        println(r.status)
    end

    temp = JSON3.read(r.body, topLayer)

    temp = temp.account

    # Type Coersions
    temp = coerceAccount(temp)

    return temp

end

"""
    getAccountSummary(config::config)

Similar to getAccount but doesnt return the order & trade & positions lists, however
it still returns a full account struct, just with these fields left undefined
"""
function getAccountSummary(config)
    r = HTTP.request("GET", string("https://", config.hostname, "/v3/accounts/", config.account, "/summary"),
    ["Authorization" => string("Bearer ", config.token), "Accept-Datetime-Format" => config.datetime])
    if r.status != 200
        println(r.status)
    end

    temp = JSON3.read(r.body, topLayer)

    temp = temp.account

    # Type Coersions
    temp = coerceAccountSummary(temp)

    return temp

end

"""
    getAccountInstruments(config::config, inst=nothing)

Returns a list of tradeable instruments details for the account

# Arguments
- inst: Can be left blank to return all tradeable instruments, or as a string csv of instruments to return their details
"""
function getAccountInstruments(config, inst=nothing)
        request = string("https://", config.hostname, "/v3/accounts/", config.account, "/instruments")
        if !isnothing(inst)
            request = string(request, "?instruments=", inst)
        end
        r = HTTP.request("GET", request, ["Authorization" => string("Bearer ", config.token),
        "Accept-Datetime-Format" => config.datetime])
        if r.status != 200
            println(r.status)
        end

        data = JSON3.read(r.body, instrumentTopLayer)
        data = data.instruments
        instruments = Vector{instrumentDetail}()
        for inst in data
            inst = coerceInstrumentDetail(inst)
            push!(instruments, inst)
        end

        return instruments
end

"""
    setAccountConfig(config::config, alias::String, marginRate::String)

Set client configurable configuration settings

# Arguments
- alias: The account alias
- marginRate: The desired decimal margin rate formatted as a string
"""
function setAccountConfig(config, alias::String, marginRate::String)
    data = accountConfig(alias, marginRate)
    r = HTTP.request("PATCH", string("https://", config.hostname, "/v3/accounts/", config.account, "/configuration"),
    ["Authorization" => string("Bearer ", config.token),
    "Accept-Datetime-Format" => config.datetime,
    "Content-Type" => "application/json"], JSON3.write(data))
    if r.status != 200
        println(r.status)
    end
    return true
end

end
