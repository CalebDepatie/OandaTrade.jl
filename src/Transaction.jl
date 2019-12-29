module Transaction

using HTTP, JSON3, Dates, CodecZlib
#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions Endpoint
#------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------
#/accounts/{accountID}/transactions/{transactionID} Endpoint
#------------------------------------------------------------------------------------
mutable struct transaction
    id
    time
    userID
    accountID
    batchID
    requestID
    type
    units
end
