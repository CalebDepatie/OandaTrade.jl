module Account
export account, getAccount

import HTTP
import JSON

# TODO: Add strict types

"The account struct given by Oanda"
struct account
    NAV # The Net Asset Value of an account
    alias # User defined alias if one exists
    balance # Current Account Balance
    createdBy # The User ID of the account creator
    createdTime # The time the account was created
    currency # The primary currency of the account
    hedging # If the account is allowed to hedge
    id # The account ID
    lastTransID # The last transaction ID
    marAvailable # The margin still available on the account
    marCloseoutMarUsed # The closeout margin used
    marCloseoutNAV # Margins closeout NAV
    marCloseoutPercent # Margin closeout percent
    marCloseoutPositionValue # Margin closeout position value
    marCloseoutUnrealisedPL # Margin closeout unrealised profit/loss
    marRate # The margin rate
    marginUsed # Amount of margin used
    openPosNum # Number of open positions
    openTradeNum # Number of open trades
    pendingOrderNum # Number of pending orders
    pl # The profit or loss over the lifetime of the account
    positionValue # Value of an accounts open positions
    resettablePL # The resetable profit/loss since last reset
    unrealizedPL # The unrealised profit/loss of the account
    withdrawalLim # The withdrawal limit of the account
    #positions # TBD requires the positions struct
    #orders # TBD requires the order struct
    #trades # TBD requires the trade struct
end

"Returns an Oanda account struct"
function getAccount(config)
    r = HTTP.request("GET", string("https://", config.hostname, "/v3/accounts/", config.account),
    ["Authorization" => string("Bearer ", config.token)])
    if r.status != 200
        println(r.status)
    end
    data = JSON.parse(String(r.body))
    acc = data["account"]
    # Look at the following hideous code ... Im sure a cleaner way exists
    temp = account(acc["NAV"], acc["alias"], acc["balance"], acc["createdByUserID"],
    acc["createdTime"], acc["currency"], acc["hedgingEnabled"], acc["id"], acc["lastTransactionID"],
    acc["marginAvailable"], acc["marginCloseoutMarginUsed"], acc["marginCloseoutNAV"],
    acc["marginCloseoutPercent"], acc["marginCloseoutPositionValue"], acc["marginCloseoutUnrealizedPL"],
    acc["marginRate"], acc["marginUsed"], acc["openPositionCount"], acc["openTradeCount"],
    acc["pendingOrderCount"], acc["pl"], acc["positionValue"], acc["resettablePL"],
    acc["unrealizedPL"], acc["withdrawalLimit"])
    return temp
end

end
