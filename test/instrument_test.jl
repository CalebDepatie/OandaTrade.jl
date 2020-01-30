using Test, Dates, Julianda

foo = Julianda.Config.loadConfig("../config")
inst = "GBP_USD" # Instrument to test with

bar = Julianda.Instrument.getCandles(foo, inst, 1)
@test length(bar.candles) == 1
dt = DateTime(2019,7,1)
bar = Julianda.Instrument.getCandles(foo, inst, dt, dt)
@test length(bar.candles) == 500
bar = Julianda.Instrument.getCandles(foo, inst, dt, 1)
@test length(bar.candles) == 1
bar = Julianda.Instrument.getCandles(foo, inst, 1, dt)
@test length(bar.candles) == 1

bar = Julianda.Instrument.getOrderBook(foo, inst, dt)
@test length(bar.buckets) == 1745

bar = Julianda.Instrument.getPositionBook(foo, inst, dt)
@test length(bar.buckets) == 598
