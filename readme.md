# Julianda

Julianda is in the very early stages of design, but I plan it to be a Julia wrapper for the Oanda FX trading API. I will eventually add functions accessing every endpoint.

## Endpoints to Do:

* Account
  * /accounts
  * ~~/accounts/{accountID}~~
  * /accounts/{accountID}/summary
  * /accounts/{accountID}/instruments
  * /accounts/{accountID}/configuration
  * /accounts/{accountID}/changes
* Instrument
  * /instruments/{instrument}/candles
  * /instruments/{instrument}/orderBook
  * /instruments/{instrument}/positionBook
* Order
  * /accounts/{accountID}/orders * POST
  * /accounts/{accountID}/orders * GET
  * /accounts/{accountID}/pendingOrders
  * /accounts/{accountID}/orders/{orderSpecifier} * GET
  * /accounts/{accountID}/orders/{orderSpecifier} * PUT
  * /accounts/{accountID}/orders/{orderSpecifier}/cancel
  * /accounts/{accountID}/orders/{orderSpecifier}/clientExtensions
* Trade
  * /accounts/{accountID}/trades
  * /accounts/{accountID}/openTrades
  * /accounts/{accountID}/trades/{tradeSpecifier}
  * /accounts/{accountID}/trades/{tradeSpecifier}/close
  * /accounts/{accountID}/trades/{tradeSpecifier}/clientExtensions
  * /accounts/{accountID}/trades/{tradeSpecifier}/orders
* Position
  * /accounts/{accountID}/positions
  * /accounts/{accountID}/openPositions
  * /accounts/{accountID}/positions/{instrument}
  * /accounts/{accountID}/positions/{instrument}/close
* Transaction
  * /accounts/{accountID}/transactions
  * /accounts/{accountID}/transactions/{transactionID}
  * /accounts/{accountID}/transactions/idrange
  * /accounts/{accountID}/transactions/sinceid
  * /accounts/{accountID}/transactions/stream
* Pricing
  * /accounts/{accountID}/candles/latest
  * /accounts/{accountID}/pricing
  * /accounts/{accountID}/pricing/stream
  * /accounts/{accountID}/instruments/{instrument}/candles
