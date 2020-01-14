using Test

@testset "account" begin
    include("account_test.jl")
end

@testset "instrument" begin
    include("instrument_test.jl")
end

@testset "order" begin
    include("order_test.jl")
end

@testset "position" begin
    include("position_test.jl")
end

@testset "transaction" begin
    include("transaction_test.jl")
end

@testset "pricing" begin
    include("pricing_test.jl")
end
