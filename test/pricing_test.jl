using Test, Dates

using Julianda

foo = Julianda.Config.loadConfig("../config")

# Checks for the right response depending on the time
dt = Dates.now()
if Dates.dayofweek(dt) >= 5
    if Dates.dayofweek(dt) == 5 & Dates.hour(dt) < 4
        @test typeof(Julianda.Pricing.getPrice(foo, "GBP_USD")) == Vector{Julianda.Pricing.price}
    elseif Dates.dayofweek(dt) == 7 & Dates.hour(dt) >= 5
        @test typeof(Julianda.Pricing.getPrice(foo, "GBP_USD")) == Vector{Julianda.Pricing.price}
    else
        @test_throws Julianda.Pricing.ClosedMarketException Julianda.Pricing.getPrice(foo, "GBP_USD")
    end
else
    @test typeof(Julianda.Pricing.getPrice(foo, "GBP_USD")) == Vector{Julianda.Pricing.price}
end
